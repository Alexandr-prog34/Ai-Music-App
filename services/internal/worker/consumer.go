package worker

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"github.com/google/uuid"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
)

const defaultRetryDelay = 2 * time.Second

var ErrNonRetryable = errors.New("worker non-retryable error")

type JobProcessor interface {
	Process(ctx context.Context, jobID uuid.UUID) error
}

type ExhaustedJobProcessor interface {
	Exhausted(ctx context.Context, jobID uuid.UUID, cause error) error
}

type Consumer struct {
	queue      ports.JobQueue
	processor  JobProcessor
	logger     *slog.Logger
	retryDelay time.Duration
}

func NewConsumer(queue ports.JobQueue, processor JobProcessor, logger *slog.Logger) *Consumer {
	if logger == nil {
		logger = slog.Default()
	}

	return &Consumer{
		queue:      queue,
		processor:  processor,
		logger:     logger,
		retryDelay: defaultRetryDelay,
	}
}

func (c *Consumer) Run(ctx context.Context) {
	if err := c.queue.Recover(ctx); err != nil {
		c.logger.Error("worker queue recover failed", "err", err)
	}

	for {
		msg, err := c.queue.DequeueJob(ctx)
		if err != nil {
			c.logger.Error("worker dequeue failed", "err", err)
			c.sleep(ctx)
			continue
		}

		if err := c.processor.Process(ctx, msg.ID); err != nil {
			c.logger.Error("worker process failed", "job_id", msg.ID.String(), "attempts", msg.Attempts, "err", err)
			c.handleFailure(ctx, msg, err)
			c.sleep(ctx)
			continue
		}

		if err := c.queue.AckJob(ctx, msg); err != nil {
			c.logger.Error("worker ack failed", "job_id", msg.ID.String(), "err", err)
			c.sleep(ctx)
		}
	}
}

func (c *Consumer) handleFailure(ctx context.Context, msg ports.JobMessage, processErr error) {
	if !c.shouldRequeue(processErr) {
		if err := c.queue.AckJob(ctx, msg); err != nil {
			c.logger.Error("worker ack after non-retryable failure failed", "job_id", msg.ID.String(), "err", err)
		}
		return
	}

	if err := c.queue.RetryJob(ctx, msg); err != nil {
		if errors.Is(err, ports.ErrMessageMovedToDLQ) {
			if exhausted, ok := c.processor.(ExhaustedJobProcessor); ok {
				if exErr := exhausted.Exhausted(ctx, msg.ID, processErr); exErr != nil {
					c.logger.Error("worker exhausted handler failed", "job_id", msg.ID.String(), "err", exErr)
				}
			}
			return
		}
		c.logger.Error("worker requeue failed", "job_id", msg.ID.String(), "err", err)
		return
	}
}

func (c *Consumer) shouldRequeue(err error) bool {
	switch {
	case err == nil:
		return false
	case errors.Is(err, domain.ErrJobNotFound):
		return false
	case errors.Is(err, domain.ErrInvalidStatusTransition):
		return false
	case errors.Is(err, ErrNonRetryable):
		return false
	default:
		return true
	}
}

func (c *Consumer) sleep(ctx context.Context) {
	timer := time.NewTimer(c.retryDelay)
	defer timer.Stop()

	select {
	case <-ctx.Done():
	case <-timer.C:
	}
}

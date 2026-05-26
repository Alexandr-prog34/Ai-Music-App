package worker

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/sunocallback"
)

type SunoCallbackProcessor interface {
	Handle(ctx context.Context, req sunocallback.Request) error
}

type SunoCallbackConsumer struct {
	queue      ports.SunoCallbackQueue
	processor  SunoCallbackProcessor
	logger     *slog.Logger
	retryDelay time.Duration
}

func NewSunoCallbackConsumer(queue ports.SunoCallbackQueue, processor SunoCallbackProcessor, logger *slog.Logger) *SunoCallbackConsumer {
	if logger == nil {
		logger = slog.Default()
	}

	return &SunoCallbackConsumer{
		queue:      queue,
		processor:  processor,
		logger:     logger,
		retryDelay: defaultRetryDelay,
	}
}

func (c *SunoCallbackConsumer) Run(ctx context.Context) {
	if err := c.queue.Recover(ctx); err != nil {
		c.logger.Error("suno callback queue recover failed", "err", err)
	}

	for {
		msg, err := c.queue.Dequeue(ctx)
		if err != nil {
			c.logger.Error("suno callback dequeue failed", "err", err)
			c.sleep(ctx)
			continue
		}

		if err := c.processor.Handle(ctx, msg.Request); err != nil {
			c.logger.Error("suno callback process failed", "task_id", msg.Request.TaskID(), "attempts", msg.Attempts, "err", err)
			c.handleFailure(ctx, msg, err)
			c.sleep(ctx)
			continue
		}

		if err := c.queue.Ack(ctx, msg); err != nil {
			c.logger.Error("suno callback ack failed", "task_id", msg.Request.TaskID(), "err", err)
			c.sleep(ctx)
		}
	}
}

func (c *SunoCallbackConsumer) handleFailure(ctx context.Context, msg ports.SunoCallbackMessage, processErr error) {
	if !c.shouldRequeue(processErr) {
		if err := c.queue.Ack(ctx, msg); err != nil {
			c.logger.Error("suno callback ack after non-retryable failure failed", "task_id", msg.Request.TaskID(), "err", err)
		}
		return
	}

	if err := c.queue.Retry(ctx, msg); err != nil {
		if errors.Is(err, ports.ErrMessageMovedToDLQ) {
			return
		}
		c.logger.Error("suno callback requeue failed", "task_id", msg.Request.TaskID(), "err", err)
	}
}

func (c *SunoCallbackConsumer) shouldRequeue(err error) bool {
	switch {
	case err == nil:
		return false
	case errors.Is(err, domain.ErrInvalidStatusTransition):
		return false
	case errors.Is(err, sunocallback.ErrInvalidCallback):
		return false
	case errors.Is(err, domain.ErrTrackNotFound):
		return false
	default:
		return true
	}
}

func (c *SunoCallbackConsumer) sleep(ctx context.Context) {
	timer := time.NewTimer(c.retryDelay)
	defer timer.Stop()

	select {
	case <-ctx.Done():
	case <-timer.C:
	}
}

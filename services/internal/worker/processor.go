package worker

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/sunocallback"
)

type retryableError interface {
	Retryable() bool
}

type sunoCallbackQueue interface {
	Enqueue(ctx context.Context, req sunocallback.Request) error
}

type Processor struct {
	jobRepo       ports.JobRepository
	sunoClient    ports.SunoClient
	notifier      ports.Notifier
	callbackURL   string
	callbackQueue sunoCallbackQueue
	pollInterval  time.Duration
	pollTimeout   time.Duration
	logger        *slog.Logger
}

func NewJobProcessor(
	jobRepo ports.JobRepository,
	sunoClient ports.SunoClient,
	notifier ports.Notifier,
	callbackURL string,
	callbackQueue sunoCallbackQueue,
	pollInterval time.Duration,
	pollTimeout time.Duration,
	logger *slog.Logger,
) *Processor {
	if logger == nil {
		logger = slog.Default()
	}

	return &Processor{
		jobRepo:       jobRepo,
		sunoClient:    sunoClient,
		notifier:      notifier,
		callbackURL:   callbackURL,
		callbackQueue: callbackQueue,
		pollInterval:  pollInterval,
		pollTimeout:   pollTimeout,
		logger:        logger,
	}
}

func (p *Processor) Process(ctx context.Context, jobID uuid.UUID) error {
	job, err := p.jobRepo.GetJob(ctx, jobID)
	if err != nil {
		return fmt.Errorf("get job: %w", err)
	}

	if job.Status != domain.JobQueued {
		return fmt.Errorf(
			"%w: job_id=%s current_status=%s",
			domain.ErrInvalidStatusTransition,
			jobID.String(),
			job.Status.String(),
		)
	}

	taskID, err := p.sunoClient.GenerateMusic(job.Params, p.callbackURL)
	if err != nil {
		var apiErr retryableError
		if errors.As(err, &apiErr) && !apiErr.Retryable() {
			if markErr := p.markFailed(ctx, job, err.Error(), true); markErr != nil {
				return fmt.Errorf("generate music: %w; mark failed: %v", err, markErr)
			}
			return fmt.Errorf("%w: %v", ErrNonRetryable, err)
		}
		return fmt.Errorf("generate music: %w", err)
	}

	if err := job.MarkProcessing(time.Now().UTC(), taskID); err != nil {
		return fmt.Errorf("mark processing: %w", err)
	}

	updated, err := p.jobRepo.UpdateJob(ctx, job)
	if err != nil {
		return fmt.Errorf("update job: %w", err)
	}
	if err := p.publish(ctx, updated); err != nil {
		return fmt.Errorf("publish processing update: %w", err)
	}

	p.logger.Info(
		"worker job marked processing",
		"job_id", updated.ID.String(),
		"task_id", taskIDValue(updated.SunoTaskID),
		"status", updated.Status.String(),
	)
	p.startPolling(updated.ID, taskID)

	return nil
}

func (p *Processor) Exhausted(ctx context.Context, jobID uuid.UUID, cause error) error {
	job, err := p.jobRepo.GetJob(ctx, jobID)
	if err != nil {
		return err
	}

	message := "worker retries exhausted"
	if cause != nil {
		message = message + ": " + cause.Error()
	}
	return p.markFailed(ctx, job, message, false)
}

func (p *Processor) markFailed(ctx context.Context, job domain.Job, message string, nonRetryable bool) error {
	if err := job.MarkFailed(time.Now().UTC(), message); err != nil {
		if errors.Is(err, domain.ErrInvalidStatusTransition) && job.Status == domain.JobFailed {
			return nil
		}
		return fmt.Errorf("mark failed: %w", err)
	}

	updated, err := p.jobRepo.UpdateJob(ctx, job)
	if err != nil {
		return fmt.Errorf("update failed job: %w", err)
	}
	if err := p.publish(ctx, updated); err != nil {
		return fmt.Errorf("publish failed update: %w", err)
	}

	p.logger.Info(
		"worker job marked failed",
		"job_id", job.ID.String(),
		"task_id", taskIDValue(job.SunoTaskID),
		"status", job.Status.String(),
		"error", message,
		"non_retryable", nonRetryable,
	)

	return nil
}

func (p *Processor) publish(ctx context.Context, job domain.Job) error {
	if p.notifier == nil {
		return nil
	}
	return p.notifier.JobUpdated(ctx, job.UserID, job.ID)
}

func (p *Processor) startPolling(jobID uuid.UUID, taskID string) {
	if !p.pollingEnabled() || strings.TrimSpace(taskID) == "" {
		return
	}

	go func() {
		ctx := context.Background()
		cancel := func() {}
		if p.pollTimeout > 0 {
			ctx, cancel = context.WithTimeout(ctx, p.pollTimeout)
		}
		defer cancel()

		if err := p.pollUntilComplete(ctx, jobID, taskID); err != nil && !errors.Is(err, context.Canceled) && !errors.Is(err, context.DeadlineExceeded) {
			p.logger.Error("worker suno polling stopped with error", "job_id", jobID.String(), "task_id", taskID, "err", err)
		}
	}()
}

func (p *Processor) pollingEnabled() bool {
	return p.callbackQueue != nil && p.pollInterval > 0
}

func (p *Processor) pollUntilComplete(ctx context.Context, jobID uuid.UUID, taskID string) error {
	ticker := time.NewTicker(p.pollInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			p.logger.Warn("worker suno polling timed out", "job_id", jobID.String(), "task_id", taskID, "timeout", p.pollTimeout.String())
			return ctx.Err()
		case <-ticker.C:
		}

		if !p.shouldContinuePolling(ctx, jobID) {
			return nil
		}

		details, err := p.sunoClient.GetGenerationDetails(ctx, taskID)
		if err != nil {
			p.logger.Warn("worker suno polling request failed", "job_id", jobID.String(), "task_id", taskID, "err", err)
			continue
		}

		req, done := callbackRequestFromDetails(taskID, details)
		if !done {
			continue
		}

		if err := p.callbackQueue.Enqueue(ctx, req); err != nil {
			p.logger.Warn("worker suno polling callback enqueue failed", "job_id", jobID.String(), "task_id", taskID, "err", err)
			continue
		}

		p.logger.Info("worker suno polling enqueued terminal callback", "job_id", jobID.String(), "task_id", taskID, "status", details.Status)
		return nil
	}
}

func (p *Processor) shouldContinuePolling(ctx context.Context, jobID uuid.UUID) bool {
	job, err := p.jobRepo.GetJob(ctx, jobID)
	if err != nil {
		if errors.Is(err, domain.ErrJobNotFound) {
			return false
		}
		p.logger.Warn("worker suno polling could not refresh job", "job_id", jobID.String(), "err", err)
		return true
	}

	switch job.Status {
	case domain.JobQueued, domain.JobProcessing:
		return true
	default:
		return false
	}
}

func callbackRequestFromDetails(taskID string, details ports.GenerationDetails) (sunocallback.Request, bool) {
	status := strings.ToUpper(strings.TrimSpace(details.Status))
	switch status {
	case "SUCCESS":
		if len(details.Results) == 0 {
			return sunocallback.Request{}, false
		}
		return sunocallback.Request{
			Code:    200,
			Message: "polled success",
			Data: sunocallback.Data{
				CallbackType: sunocallback.TypeComplete,
				TaskID:       taskID,
				Results:      details.Results,
			},
		}, true
	case "CALLBACK_EXCEPTION":
		if len(details.Results) > 0 {
			return sunocallback.Request{
				Code:    200,
				Message: "callback exception resolved via polling",
				Data: sunocallback.Data{
					CallbackType: sunocallback.TypeComplete,
					TaskID:       taskID,
					Results:      details.Results,
				},
			}, true
		}
		return sunocallback.Request{
			Code:    200,
			Message: firstNonEmpty(details.ErrorMessage, "callback exception"),
			Data: sunocallback.Data{
				CallbackType: sunocallback.TypeError,
				TaskID:       taskID,
			},
		}, true
	case "CREATE_TASK_FAILED", "GENERATE_AUDIO_FAILED", "SENSITIVE_WORD_ERROR", "FAILED", "ERROR":
		return sunocallback.Request{
			Code:    200,
			Message: firstNonEmpty(details.ErrorMessage, strings.ToLower(status)),
			Data: sunocallback.Data{
				CallbackType: sunocallback.TypeError,
				TaskID:       taskID,
			},
		}, true
	default:
		return sunocallback.Request{}, false
	}
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		trimmed := strings.TrimSpace(value)
		if trimmed != "" {
			return trimmed
		}
	}
	return ""
}

func taskIDValue(taskID *string) string {
	if taskID == nil {
		return ""
	}
	return *taskID
}

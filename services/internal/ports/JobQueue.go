package ports

import (
	"context"

	"github.com/google/uuid"
)

type JobMessage struct {
	ID       uuid.UUID
	Attempts int
	Receipt  string
}

type JobQueue interface {
	EnqueueJob(ctx context.Context, jobID uuid.UUID) error
	DequeueJob(ctx context.Context) (JobMessage, error)
	AckJob(ctx context.Context, msg JobMessage) error
	RetryJob(ctx context.Context, msg JobMessage) error
	Recover(ctx context.Context) error
}

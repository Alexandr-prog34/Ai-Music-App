package ports

import (
	"context"

	"github.com/google/uuid"
)

// JobQueue — интерфейс очереди задач.
type JobQueue interface {
	// EnqueueJob — добавляет job_id в очередь.
	EnqueueJob(ctx context.Context, jobID uuid.UUID) error

	// DequeueJob — извлекает job_id из очереди для обработки.
	DequeueJob(ctx context.Context) (uuid.UUID, error)
}

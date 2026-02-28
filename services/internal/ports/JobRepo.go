package ports

import (
	"context"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/google/uuid"
)

type JobRepo interface {
	CreateJob(ctx context.Context, job domain.Job) (domain.Job, error)
	UpdateJob(ctx context.Context, job domain.Job) (domain.Job, error)

	GetJob(ctx context.Context, id uuid.UUID) (domain.Job, error)

	// ListJobs — по контракту listjobs. Возвращаем:
	// - список
	// - total (для пагинации на клиенте)
	ListJobs(ctx context.Context, userID uuid.UUID, status *domain.JobStatus, limit, offset int) ([]domain.Job, int, error)
}

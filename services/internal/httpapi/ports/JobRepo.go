package ports

import (
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/google/uuid"
)

type JobRepo interface {
	CreateJob(job *domain.Job) (domain.Job, error)

	UpdateJob(job *domain.Job) (domain.Job, error)

	GetJob(JobId uuid.UUID) (domain.Job, error)
}

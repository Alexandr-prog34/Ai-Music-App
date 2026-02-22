package ports

import "github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"

type JobRepo interface {
	CreateJob(job *domain.Job) (domain.Job, error)

	UpdateJob(job *domain.Job) (domain.Job, error)

	GetJob(JobId string) (domain.Job, error)
}

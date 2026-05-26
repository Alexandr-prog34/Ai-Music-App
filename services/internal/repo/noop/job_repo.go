package noop

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
)

// !!!Просто реализовываем интерфейсы репозиториев, пока что просто зашлушки для проверки
// работы редиски, потом реализуем по нормальному
var ErrNotImplemented = errors.New("not implemented")

type JobRepo struct{}

func NewJobRepo() ports.JobRepository {
	return &JobRepo{}
}

func (r *JobRepo) CreateJob(ctx context.Context, job domain.Job) (domain.Job, error) {
	// Заглушка: “сохраняем” и просто возвращаем обратно.
	return job, nil
}

func (r *JobRepo) UpdateJob(ctx context.Context, job domain.Job) (domain.Job, error) {
	return domain.Job{}, ErrNotImplemented
}

func (r *JobRepo) GetJob(ctx context.Context, id uuid.UUID) (domain.Job, error) {
	return domain.Job{}, ErrNotImplemented
}

func (r *JobRepo) ListJobs(ctx context.Context, deviceID uuid.UUID, status *domain.JobStatus, limit, offset int) ([]domain.Job, int, error) {
	return nil, 0, ErrNotImplemented
}

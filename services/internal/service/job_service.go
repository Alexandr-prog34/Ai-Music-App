package service

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
)

// JobService — бизнес-логика для job'ов.
type JobService struct {
	jobRepo  ports.JobRepo
	jobQueue ports.JobQueue
}

// NewJobService — конструктор.
func NewJobService(jobRepo ports.JobRepo, jobQueue ports.JobQueue) *JobService {
	return &JobService{
		jobRepo:  jobRepo,
		jobQueue: jobQueue,
	}
}

// CreateJob — правильный порядок:
// 1) сначала сохранить в БД
// 2) потом положить в очередь
func (s *JobService) CreateJob(ctx context.Context, deviceID uuid.UUID, params domain.JobParams) (domain.Job, error) {
	now := time.Now().UTC()

	params.Normalize()
	if err := params.Validate(); err != nil {
		return domain.Job{}, err
	}

	j := domain.Job{
		ID:        uuid.New(),
		UserID:    deviceID, // пока DeviceID нет в домене — кладём сюда
		Status:    domain.JobQueued,
		Params:    params,
		CreatedAt: now,
		UpdatedAt: now,
	}

	// 1) сначала сохранить в БД
	created, err := s.jobRepo.CreateJob(ctx, j)
	if err != nil {
		return domain.Job{}, err
	}

	// 2) потом положить в очередь
	if err := s.jobQueue.EnqueueJob(ctx, created.ID); err != nil {
		return domain.Job{}, err
	}

	return created, nil
}
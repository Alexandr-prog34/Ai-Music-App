package service

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/httpapi/dto"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/httpapi/ports"
)

// JobService — бизнес-логика для job'ов.
// Пока: кладём job в очередь Redis и возвращаем DTO.
type JobService struct {
	jobQueue ports.JobQueue
}

// NewJobService — конструктор.
func NewJobService(jobQueue ports.JobQueue) *JobService {
	return &JobService{jobQueue: jobQueue}
}

// CreateJob — валидируем входные данные, создаём ID, кладём в Redis, возвращаем DTO.
func (s *JobService) CreateJob(ctx context.Context, req dto.CreateJobRequest) (dto.Job, error) {
	// 1) DTO -> domain.JobParams
	params := req.ToJobParams()

	// 2) Валидация доменных параметров
	if err := params.Validate(); err != nil {
		return dto.Job{}, err
	}

	// 3) Генерим ID job'ы
	jobID := uuid.New()
	now := time.Now().UTC()

	// 4) Кладём jobID в Redis очередь
	if err := s.jobQueue.EnqueueJob(ctx, jobID); err != nil {
		return dto.Job{}, err
	}

	// 5) Собираем доменную Job (минимально нужную)
	j := domain.Job{
		ID:        jobID,
		Status:    domain.JobQueued,
		Params:    params,
		CreatedAt: now,
		UpdatedAt: now,
	}

	// 6) Мапим domain.Job -> dto.Job по новой схеме
	return dto.NewJob(j), nil
}
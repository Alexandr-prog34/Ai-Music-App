package service

import (
	"context"
	"fmt"

	"github.com/google/uuid"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
)

type JobReadService struct {
	jobRepo   ports.JobRepository
	userRepo  ports.UserRepository
	trackRepo ports.TrackRepository
	hydrator  *AssetHydrator
}

func NewJobReadService(
	jobRepo ports.JobRepository,
	userRepo ports.UserRepository,
	trackRepo ports.TrackRepository,
	storage ports.ObjectStorage,
) *JobReadService {
	return &JobReadService{
		jobRepo:   jobRepo,
		userRepo:  userRepo,
		trackRepo: trackRepo,
		hydrator:  NewAssetHydrator(storage),
	}
}

func (s *JobReadService) GetJob(ctx context.Context, installID uuid.UUID, jobID uuid.UUID) (domain.Job, error) {
	userID, err := s.resolveUserID(ctx, installID)
	if err != nil {
		return domain.Job{}, err
	}
	return s.GetJobForUser(ctx, userID, jobID)
}

func (s *JobReadService) GetJobForUser(ctx context.Context, userID uuid.UUID, jobID uuid.UUID) (domain.Job, error) {
	job, err := s.jobRepo.GetJob(ctx, jobID)
	if err != nil {
		return domain.Job{}, err
	}
	if job.UserID != userID {
		return domain.Job{}, fmt.Errorf("%w", domain.ErrJobNotFound)
	}
	return s.attachTracks(ctx, job)
}

func (s *JobReadService) ListJobs(ctx context.Context, installID uuid.UUID, status *domain.JobStatus, limit, offset int) ([]domain.Job, int, error) {
	userID, err := s.resolveUserID(ctx, installID)
	if err != nil {
		return nil, 0, err
	}
	return s.ListJobsForUser(ctx, userID, status, limit, offset)
}

func (s *JobReadService) ListJobsForUser(ctx context.Context, userID uuid.UUID, status *domain.JobStatus, limit, offset int) ([]domain.Job, int, error) {
	jobs, total, err := s.jobRepo.ListJobs(ctx, userID, status, limit, offset)
	if err != nil {
		return nil, 0, err
	}

	out := make([]domain.Job, 0, len(jobs))
	for _, job := range jobs {
		hydrated, err := s.attachTracks(ctx, job)
		if err != nil {
			return nil, 0, err
		}
		out = append(out, hydrated)
	}
	return out, total, nil
}

func (s *JobReadService) attachTracks(ctx context.Context, job domain.Job) (domain.Job, error) {
	tracks, err := s.trackRepo.ListTracksByJobID(ctx, job.ID)
	if err != nil {
		return domain.Job{}, err
	}

	hydratedTracks, err := s.hydrator.HydrateTracks(ctx, tracks)
	if err != nil {
		return domain.Job{}, err
	}

	job.Tracks = hydratedTracks
	return job, nil
}

func (s *JobReadService) resolveUserID(ctx context.Context, installID uuid.UUID) (uuid.UUID, error) {
	user, err := s.userRepo.GetOrCreateUser(ctx, installID)
	if err != nil {
		return uuid.Nil, err
	}
	return user.ID, nil
}

package service

import (
	"context"
	"fmt"

	"github.com/google/uuid"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
)

type TrackService struct {
	userRepo  ports.UserRepository
	jobRepo   ports.JobRepository
	trackRepo ports.TrackRepository
	hydrator  *AssetHydrator
	storage   ports.ObjectStorage
}

func NewTrackService(
	userRepo ports.UserRepository,
	jobRepo ports.JobRepository,
	trackRepo ports.TrackRepository,
	storage ports.ObjectStorage,
) *TrackService {
	return &TrackService{
		userRepo:  userRepo,
		jobRepo:   jobRepo,
		trackRepo: trackRepo,
		hydrator:  NewAssetHydrator(storage),
		storage:   storage,
	}
}

func (s *TrackService) GetTrack(ctx context.Context, installID uuid.UUID, trackID uuid.UUID) (domain.Track, error) {
	userID, err := s.resolveUserID(ctx, installID)
	if err != nil {
		return domain.Track{}, err
	}
	return s.GetTrackForUser(ctx, userID, trackID)
}

func (s *TrackService) GetTrackForUser(ctx context.Context, userID uuid.UUID, trackID uuid.UUID) (domain.Track, error) {
	track, err := s.loadOwnedTrack(ctx, userID, trackID)
	if err != nil {
		return domain.Track{}, err
	}

	return s.hydrator.HydrateTrack(ctx, track)
}

func (s *TrackService) loadOwnedTrack(ctx context.Context, userID uuid.UUID, trackID uuid.UUID) (domain.Track, error) {
	track, err := s.trackRepo.GetTrack(ctx, trackID)
	if err != nil {
		return domain.Track{}, err
	}

	job, err := s.jobRepo.GetJob(ctx, track.JobID)
	if err != nil {
		return domain.Track{}, err
	}
	if job.UserID != userID {
		return domain.Track{}, fmt.Errorf("%w", domain.ErrTrackNotFound)
	}

	return track, nil
}

func (s *TrackService) ListTracks(ctx context.Context, installID uuid.UUID, favorite *bool, limit, offset int) ([]domain.Track, int, error) {
	userID, err := s.resolveUserID(ctx, installID)
	if err != nil {
		return nil, 0, err
	}

	tracks, total, err := s.trackRepo.ListTracks(ctx, userID, favorite, limit, offset)
	if err != nil {
		return nil, 0, err
	}

	hydrated, err := s.hydrator.HydrateTracks(ctx, tracks)
	if err != nil {
		return nil, 0, err
	}

	return hydrated, total, nil
}

func (s *TrackService) DeleteTrack(ctx context.Context, installID uuid.UUID, trackID uuid.UUID) error {
	userID, err := s.resolveUserID(ctx, installID)
	if err != nil {
		return err
	}

	track, err := s.loadOwnedTrack(ctx, userID, trackID)
	if err != nil {
		return err
	}

	if err := s.trackRepo.DeleteTrack(ctx, trackID, userID); err != nil {
		return err
	}

	if s.storage == nil {
		return nil
	}

	if err := s.storage.DeleteObject(ctx, track.AudioBucket, track.AudioKey); err != nil {
		return err
	}
	if track.ImageBucket != nil && track.ImageKey != nil && *track.ImageKey != "" {
		if err := s.storage.DeleteObject(ctx, *track.ImageBucket, *track.ImageKey); err != nil {
			return err
		}
	}
	return nil
}

func (s *TrackService) SetFavorite(ctx context.Context, installID uuid.UUID, trackID uuid.UUID, favorite bool) error {
	userID, err := s.resolveUserID(ctx, installID)
	if err != nil {
		return err
	}
	return s.trackRepo.SetFavorite(ctx, trackID, userID, favorite)
}

func (s *TrackService) DownloadTrackURL(ctx context.Context, installID uuid.UUID, trackID uuid.UUID) (string, error) {
	track, err := s.GetTrack(ctx, installID, trackID)
	if err != nil {
		return "", err
	}
	return track.AudioURL, nil
}

func (s *TrackService) resolveUserID(ctx context.Context, installID uuid.UUID) (uuid.UUID, error) {
	user, err := s.userRepo.GetOrCreateUser(ctx, installID)
	if err != nil {
		return uuid.Nil, err
	}
	return user.ID, nil
}

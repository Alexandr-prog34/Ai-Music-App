package service

import (
	"context"
	"fmt"
	"log/slog"
	"net/url"
	"path"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/sunocallback"
)

type SunoCallbackService struct {
	jobRepo   ports.JobRepository
	trackRepo ports.TrackRepository
	storage   ports.ObjectStorage
	notifier  ports.Notifier
	logger    *slog.Logger
}

func NewSunoCallbackService(
	jobRepo ports.JobRepository,
	trackRepo ports.TrackRepository,
	storage ports.ObjectStorage,
	notifier ports.Notifier,
	logger *slog.Logger,
) *SunoCallbackService {
	if logger == nil {
		logger = slog.Default()
	}

	return &SunoCallbackService{
		jobRepo:   jobRepo,
		trackRepo: trackRepo,
		storage:   storage,
		notifier:  notifier,
		logger:    logger,
	}
}

func (s *SunoCallbackService) Handle(ctx context.Context, req sunocallback.Request) error {
	job, err := s.jobRepo.GetJobBySunoTaskID(ctx, req.TaskID())
	if err != nil {
		return err
	}

	switch req.CallbackType() {
	case sunocallback.TypeText, sunocallback.TypeFirst:
		s.logger.Info(
			"suno callback progress",
			"job_id", job.ID.String(),
			"task_id", req.TaskID(),
			"callback_type", string(req.CallbackType()),
			"message", req.Message,
		)
		return nil
	case sunocallback.TypeComplete:
		return s.handleComplete(ctx, job, req)
	case sunocallback.TypeError:
		return s.handleError(ctx, job, req.ErrorMessage())
	default:
		return sunocallback.Invalid(sunocallback.ErrCallbackTypeInvalid, "got=%q", string(req.CallbackType()))
	}
}

func (s *SunoCallbackService) handleComplete(ctx context.Context, job domain.Job, req sunocallback.Request) error {
	tracks := make([]domain.Track, 0, len(req.Results()))
	for _, result := range req.Results() {
		track, err := s.buildTrack(ctx, job, result)
		if err != nil {
			return err
		}

		created, err := s.trackRepo.CreateTrack(ctx, track)
		if err != nil {
			return fmt.Errorf("create track: %w", err)
		}
		tracks = append(tracks, created)
	}

	updatedJob := job
	if job.Status != domain.JobReady {
		if err := job.MarkReady(time.Now().UTC(), tracks); err != nil {
			return err
		}
		updated, err := s.jobRepo.UpdateJob(ctx, job)
		if err != nil {
			return fmt.Errorf("update job ready: %w", err)
		}
		updatedJob = updated
	}

	if err := s.publishJobUpdated(ctx, updatedJob); err != nil {
		return err
	}

	s.logger.Info(
		"suno callback complete",
		"job_id", job.ID.String(),
		"task_id", req.TaskID(),
		"tracks", len(tracks),
	)

	return nil
}

func (s *SunoCallbackService) handleError(ctx context.Context, job domain.Job, message string) error {
	updatedJob := job
	if job.Status != domain.JobFailed {
		if err := job.MarkFailed(time.Now().UTC(), message); err != nil {
			return err
		}
		updated, err := s.jobRepo.UpdateJob(ctx, job)
		if err != nil {
			return fmt.Errorf("update job failed: %w", err)
		}
		updatedJob = updated
	}

	if err := s.publishJobUpdated(ctx, updatedJob); err != nil {
		return err
	}

	s.logger.Info(
		"suno callback failed",
		"job_id", job.ID.String(),
		"task_id", taskIDValue(job.SunoTaskID),
		"message", message,
	)

	return nil
}

func (s *SunoCallbackService) buildTrack(ctx context.Context, job domain.Job, result sunocallback.Result) (domain.Track, error) {
	audioID := strings.TrimSpace(result.AudioID)
	if audioID == "" {
		return domain.Track{}, domain.InvalidInput(domain.ErrTrackSunoAudioIDReq)
	}

	audioSourceURL := firstNonEmpty(result.AudioURL, result.SourceAudioURL)
	if audioSourceURL == "" {
		return domain.Track{}, domain.InvalidInput(domain.ErrTrackAudioURLRequired)
	}

	if result.DurationSec == nil || *result.DurationSec <= 0 {
		return domain.Track{}, domain.InvalidInput(domain.ErrInvalidInput, "track.duration is required")
	}

	audioKey := fmt.Sprintf("jobs/%s/audio/%s.mp3", job.ID.String(), audioID)
	audioBucket, err := s.storage.UploadFromURL(ctx, audioSourceURL, audioKey)
	if err != nil {
		return domain.Track{}, fmt.Errorf("upload audio to storage: %w", err)
	}

	var imageBucket *string
	var imageKey *string
	imageSourceURL := firstNonEmpty(result.ImageURL, result.SourceImageURL)
	if imageSourceURL != "" {
		key := fmt.Sprintf("jobs/%s/images/%s%s", job.ID.String(), audioID, extensionFromURL(imageSourceURL, ".jpg"))
		bucket, uploadErr := s.storage.UploadFromURL(ctx, imageSourceURL, key)
		if uploadErr != nil {
			return domain.Track{}, fmt.Errorf("upload image to storage: %w", uploadErr)
		}
		imageBucket = &bucket
		imageKey = &key
	}

	title := strings.TrimSpace(firstNonEmpty(result.Title, job.Params.Title))
	if title == "" {
		title = audioID
	}

	track := domain.Track{
		ID:          uuid.New(),
		JobID:       job.ID,
		SunoAudioID: audioID,
		Title:       title,
		Tags:        normalizeOptionalPtr(result.Tags),
		Duration:    time.Duration(*result.DurationSec * float64(time.Second)),
		AudioBucket: audioBucket,
		AudioKey:    audioKey,
		ImageBucket: imageBucket,
		ImageKey:    imageKey,
	}

	if err := track.Validate(); err != nil {
		return domain.Track{}, err
	}

	return track, nil
}

func (s *SunoCallbackService) publishJobUpdated(ctx context.Context, job domain.Job) error {
	if s.notifier == nil {
		return nil
	}
	if err := s.notifier.JobUpdated(ctx, job.UserID, job.ID); err != nil {
		return fmt.Errorf("publish job updated: %w", err)
	}
	return nil
}

func firstNonEmpty(values ...*string) string {
	for _, value := range values {
		if value == nil {
			continue
		}
		trimmed := strings.TrimSpace(*value)
		if trimmed != "" {
			return trimmed
		}
	}
	return ""
}

func normalizeOptionalPtr(value *string) *string {
	if value == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func extensionFromURL(raw string, fallback string) string {
	parsed, err := url.Parse(strings.TrimSpace(raw))
	if err != nil {
		return fallback
	}
	ext := strings.ToLower(path.Ext(parsed.Path))
	if ext == "" {
		return fallback
	}
	return ext
}

func taskIDValue(taskID *string) string {
	if taskID == nil {
		return ""
	}
	return *taskID
}

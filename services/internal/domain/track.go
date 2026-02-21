package domain

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

type Track struct {
	ID    uuid.UUID
	JobID uuid.UUID

	// suno_audio_id — id конкретного результата у Suno (важно для идемпотентности callback).
	SunoAudioID string

	Title string
	Tags  *string

	DurationSec float64

	// Presigned URL из вашего S3 (как в YAML)
	AudioURL string

	StreamURL *string
	ImageURL  *string

	IsFavorite bool

	CreatedAt time.Time
}

func (t Track) Validate() error {
	if t.ID == uuid.Nil {
		return errors.New("track.id is required")
	}
	if t.JobID == uuid.Nil {
		return errors.New("track.job_id is required")
	}
	if strings.TrimSpace(t.SunoAudioID) == "" {
		return errors.New("track.suno_audio_id is required")
	}
	if strings.TrimSpace(t.Title) == "" {
		return errors.New("track.title is required")
	}
	if strings.TrimSpace(t.AudioURL) == "" {
		return errors.New("track.audio_url is required")
	}
	return nil
}

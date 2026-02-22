package domain

import (
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
		return InvalidInput(ErrTrackIDRequired)
	}
	if t.JobID == uuid.Nil {
		return InvalidInput(ErrTrackJobIDRequired)
	}
	if strings.TrimSpace(t.SunoAudioID) == "" {
		return InvalidInput(ErrTrackSunoAudioIDReq)
	}
	if strings.TrimSpace(t.Title) == "" {
		return InvalidInput(ErrTrackTitleRequired)
	}
	if strings.TrimSpace(t.AudioURL) == "" {
		return InvalidInput(ErrTrackAudioURLRequired)
	}
	return nil
}

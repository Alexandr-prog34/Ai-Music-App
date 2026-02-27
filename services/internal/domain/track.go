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

	// Координаты объекта в MinIO/S3.
	// Это то, что хранится в БД и не протухает.
	AudioBucket string
	AudioKey    string

	// Обложка (если есть)
	ImageBucket *string
	ImageKey    *string

	// Временные/вычисляемые поля для отдачи клиенту.
	// В БД их хранить не нужно, т.к. presigned URL протухают.
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

	// Главное изменение: для сохранения в БД требуем bucket/key,
	// а не presigned URL.
	if strings.TrimSpace(t.AudioBucket) == "" || strings.TrimSpace(t.AudioKey) == "" {
		return InvalidInput(ErrTrackAudioStorageRequired)
	}

	return nil
}

// ValidateForResponse — строгая валидация для того, что отдаём клиенту.
// (Например, перед маппингом в DTO.)
func (t Track) ValidateForResponse() error {
	if err := t.Validate(); err != nil {
		return err
	}
	if strings.TrimSpace(t.AudioURL) == "" {
		return InvalidInput(ErrTrackAudioURLRequired)
	}
	return nil
}

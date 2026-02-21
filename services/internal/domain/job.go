package domain

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

// JobParams — то, что приходит от фронта (CreateJobRequest) и хранится в Job.
type JobParams struct {
	Prompt       string
	CustomMode   bool
	Style        *string
	Title        *string
	Instrumental bool
	Model        SunoModel
	VocalGender  *VocalGender
	NegativeTags *string
}

// Validate — правила из контракта (мин/макс длины + минимальные смысловые проверки).
func (p JobParams) Validate() error {
	prompt := strings.TrimSpace(p.Prompt)
	if prompt == "" {
		return errors.New("prompt is required")
	}
	if len(prompt) > 5000 {
		return errors.New("prompt is too long (max 5000)")
	}
	if p.Style != nil && len(strings.TrimSpace(*p.Style)) > 1000 {
		return errors.New("style is too long (max 1000)")
	}
	if p.Title != nil && len(strings.TrimSpace(*p.Title)) > 80 {
		return errors.New("title is too long (max 80)")
	}
	if p.NegativeTags != nil && len(strings.TrimSpace(*p.NegativeTags)) > 200 {
		return errors.New("negative_tags is too long (max 200)")
	}

	// Модель по умолчанию из YAML: V4_5ALL
	if p.Model == "" {
		p.Model = SunoModelV45All
	}

	// (Опционально) если instrumental=true, vocal_gender не имеет смысла — можно игнорировать или валидировать.
	return nil
}

// Job — доменная сущность, 1 job -> (обычно) 2 tracks от Suno (как у вас описано в YAML).
type Job struct {
	ID     uuid.UUID
	UserID uuid.UUID

	Status JobStatus

	// Параметры из CreateJobRequest
	Params JobParams

	// suno_task_id — taskId, который вернул Suno при создании генерации.
	// null в API -> nil здесь
	SunoTaskID *string

	// tracks — заполняется при status=ready (по контракту).
	Tracks []Track

	// error — если status=failed
	Error *string

	CreatedAt time.Time
	UpdatedAt time.Time

	// --- Внутренние поля (не обязаны светиться наружу, но полезны для core) ---
	Attempts   int        // сколько раз пытались обработать/дожать задачу
	StartedAt  *time.Time // когда начали processing
	FinishedAt *time.Time // когда пришёл финальный callback ready/failed
}

// Convenience helpers для бизнес-логики.

func (j Job) IsFinal() bool {
	return j.Status == JobReady || j.Status == JobFailed
}

func (j *Job) MarkProcessing(now time.Time, sunoTaskID string) error {
	if j.Status != JobQueued {
		// идемпотентно: если уже processing — ок
		if j.Status == JobProcessing {
			return nil
		}
		return errors.New("invalid status transition to processing")
	}
	j.Status = JobProcessing
	j.UpdatedAt = now
	if j.StartedAt == nil {
		j.StartedAt = &now
	}
	j.Attempts++
	if j.SunoTaskID == nil && strings.TrimSpace(sunoTaskID) != "" {
		v := strings.TrimSpace(sunoTaskID)
		j.SunoTaskID = &v
	}
	return nil
}

func (j *Job) MarkReady(now time.Time, tracks []Track) error {
	if j.Status != JobProcessing && j.Status != JobQueued {
		// если callback прилетел повторно — не ломаемся
		if j.Status == JobReady {
			return nil
		}
		return errors.New("invalid status transition to ready")
	}
	j.Status = JobReady
	j.Error = nil
	j.Tracks = tracks
	j.UpdatedAt = now
	j.FinishedAt = &now
	return nil
}

func (j *Job) MarkFailed(now time.Time, msg string) error {
	if j.Status != JobProcessing && j.Status != JobQueued {
		if j.Status == JobFailed {
			return nil
		}
		return errors.New("invalid status transition to failed")
	}
	j.Status = JobFailed
	m := strings.TrimSpace(msg)
	j.Error = &m
	j.UpdatedAt = now
	j.FinishedAt = &now
	return nil
}

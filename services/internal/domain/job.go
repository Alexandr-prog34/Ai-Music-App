package domain

import (
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

func (p *JobParams) Normalize() {
	p.Prompt = strings.TrimSpace(p.Prompt)

	if p.Style != nil {
		v := strings.TrimSpace(*p.Style)
		// Если стиль пустой после trim — можно оставить пустую строку,
		// либо превратить в nil. Я рекомендую превращать в nil.
		if v == "" {
			p.Style = nil
		} else {
			p.Style = &v
		}
	}

	if p.Title != nil {
		v := strings.TrimSpace(*p.Title)
		if v == "" {
			p.Title = nil
		} else {
			p.Title = &v
		}
	}

	if p.NegativeTags != nil {
		v := strings.TrimSpace(*p.NegativeTags)
		if v == "" {
			p.NegativeTags = nil
		} else {
			p.NegativeTags = &v
		}
	}

	// Дефолтная модель (по вашему контракту)
	if p.Model == "" {
		p.Model = SunoModelV45All
	}
}

func (p JobParams) Validate() error {
	if p.Prompt == "" {
		return InvalidInput(ErrPromptRequired)
	}

	if p.Model != "" && !p.Model.isValid() {
		return InvalidInput(ErrModelInvalid, "got=%q", p.Model.String())
	}

	// vocal_gender: если пришёл — должен быть валиден
	if p.VocalGender != nil && !(*p.VocalGender).isValid() {
		return InvalidInput(ErrVocalGenderInvalid, "got=%q", (*p.VocalGender).String())
	}

	if err := p.Model.Validate(); err != nil {
		// Уже InvalidInput внутри, можно просто вернуть.
		return err
	}

	if p.CustomMode {
		if p.Style == nil {
			return InvalidInput(ErrStyleRequiredCustom)
		}
		if p.Title == nil {
			return InvalidInput(ErrTitleRequiredCustom)
		}

		// prompt limit
		switch p.Model {
		case SunoModelV4:
			if len(p.Prompt) > 3000 {
				return InvalidInput(ErrPromptTooLong, "model=%s max=%d got=%d", p.Model, 3000, len(p.Prompt))
			}
		default:
			if len(p.Prompt) > 5000 {
				return InvalidInput(ErrPromptTooLong, "model=%s max=%d got=%d", p.Model, 5000, len(p.Prompt))
			}
		}

		// style limit
		switch p.Model {
		case SunoModelV4:
			if len(*p.Style) > 200 {
				return InvalidInput(ErrStyleTooLong, "model=%s max=%d got=%d", p.Model, 200, len(*p.Style))
			}
		default:
			if len(*p.Style) > 1000 {
				return InvalidInput(ErrStyleTooLong, "model=%s max=%d got=%d", p.Model, 1000, len(*p.Style))
			}
		}

		// title limit
		switch p.Model {
		case SunoModelV4, SunoModelV45All:
			if len(*p.Title) > 80 {
				return InvalidInput(ErrTitleTooLong, "model=%s max=%d got=%d", p.Model, 80, len(*p.Title))
			}
		case SunoModelV45, SunoModelV45Plus, SunoModelV5:
			if len(*p.Title) > 100 {
				return InvalidInput(ErrTitleTooLong, "model=%s max=%d got=%d", p.Model, 100, len(*p.Title))
			}
		default:
			// теоретически не случится, но пусть будет
			return InvalidInput(ErrModelInvalid, "got=%q", p.Model.String())
		}

	} else {
		// non-custom mode
		if len(p.Prompt) > 500 {
			return InvalidInput(ErrPromptTooLong, "mode=non_custom max=%d got=%d", 500, len(p.Prompt))
		}
		if p.Style != nil {
			return InvalidInput(ErrStyleMustBeEmptyNonCustom)
		}
		if p.Title != nil {
			return InvalidInput(ErrTitleMustBeEmptyNonCustom)
		}
		if p.NegativeTags != nil {
			return InvalidInput(ErrNegativeTagsMustBeEmptyNonCustom)
		}
		if p.VocalGender != nil {
			return InvalidInput(ErrVocalGenderMustBeEmptyNonCustom)
		}
	}

	if p.VocalGender != nil {
		if p.Instrumental {
			return InvalidInput(ErrVocalGenderNotAllowedInstrumental)
		}
		if err := (*p.VocalGender).Validate(); err != nil {
			return err
		}
	}

	if p.NegativeTags != nil && len(*p.NegativeTags) > 200 {
		return InvalidInput(ErrNegativeTagsTooLong, "max=%d got=%d", 200, len(*p.NegativeTags))
	}

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

func (j *Job) MarkProcessing(now time.Time, sunoTaskID string) error {
	if j.Status != JobQueued {
		// идемпотентно: если уже processing — ок
		if j.Status == JobProcessing {
			return nil
		}
		return InvalidInput(
			ErrInvalidStatusTransition,
			"from=%s to=%s",
			j.Status, JobProcessing,
		)
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
	if j.Status != JobProcessing {
		// идемпотентность: повторный complete callback
		if j.Status == JobReady {
			return nil
		}
		return InvalidInput(
			ErrInvalidStatusTransition,
			"from=%s to=%s",
			j.Status, JobReady,
		)
	}

	j.Status = JobReady
	j.Error = nil
	j.Tracks = tracks
	j.UpdatedAt = now
	j.FinishedAt = &now
	return nil
}

func (j *Job) MarkFailed(now time.Time, msg string) error {
	if j.Status != JobProcessing {
		// идемпотентность: повторный error callback
		if j.Status == JobFailed {
			return nil
		}
		return InvalidInput(
			ErrInvalidStatusTransition,
			"from=%s to=%s",
			j.Status, JobFailed,
		)
	}

	j.Status = JobFailed
	m := strings.TrimSpace(msg)
	j.Error = &m
	j.UpdatedAt = now
	j.FinishedAt = &now
	return nil
}

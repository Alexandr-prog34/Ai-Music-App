package suno

import (
	"strings"
)

// SunoCallbackType — стадии callback, как вы описали в YAML.
type SunoCallbackType string

const (
	SunoCallbackText     SunoCallbackType = "text"
	SunoCallbackFirst    SunoCallbackType = "first"
	SunoCallbackComplete SunoCallbackType = "complete"
	SunoCallbackError    SunoCallbackType = "error"
)

func (t SunoCallbackType) isValid() bool {
	switch t {
	case SunoCallbackText, SunoCallbackFirst, SunoCallbackComplete, SunoCallbackError:
		return true
	default:
		return false
	}
}

func (r SunoCallbackRequest) Validate() error {
	if strings.TrimSpace(r.TaskID) == "" {
		return InvalidCallback(ErrTaskIDRequired)
	}

	if !r.CallbackType.isValid() {
		return InvalidCallback(ErrCallbackTypeInvalid, "got=%q", string(r.CallbackType))
	}

	if r.CallbackType == SunoCallbackComplete && len(r.Results) == 0 {
		return InvalidCallback(ErrResultsRequiredForComplete)
	}

	if r.CallbackType == SunoCallbackError && r.ErrorMessage == nil {
		return InvalidCallback(ErrErrorMessageRequired)
	}

	return nil
}

// SunoCallbackRequest — минимальная форма callback от Suno.
// ВАЖНО: точные поля могут отличаться (taskId vs task_id).
// Когда будете делать реальную интеграцию — подгоним под фактический payload.
type SunoCallbackRequest struct {
	TaskID       string           `json:"taskId"`
	CallbackType SunoCallbackType `json:"callbackType"`
	ErrorMessage *string          `json:"errorMessage,omitempty"`

	// results может быть массивом треков
	Results []SunoCallbackResult `json:"results,omitempty"`
}

type SunoCallbackResult struct {
	AudioID     string   `json:"audioId"`
	Title       string   `json:"title"`
	Tags        *string  `json:"tags,omitempty"`
	DurationSec *float64 `json:"duration,omitempty"`

	AudioURL  *string `json:"audioUrl,omitempty"`
	StreamURL *string `json:"streamUrl,omitempty"`
	ImageURL  *string `json:"imageUrl,omitempty"`
}

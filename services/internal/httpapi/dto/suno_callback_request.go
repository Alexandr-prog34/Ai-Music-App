package dto

// SunoCallbackType — стадии callback, как вы описали в YAML.
type SunoCallbackType string

const (
	SunoCallbackText     SunoCallbackType = "text"
	SunoCallbackFirst    SunoCallbackType = "first"
	SunoCallbackComplete SunoCallbackType = "complete"
	SunoCallbackError    SunoCallbackType = "error"
)

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
	AudioID     string  `json:"audioId"`
	Title       string  `json:"title"`
	Tags        *string `json:"tags,omitempty"`
	DurationSec float64 `json:"duration,omitempty"`

	AudioURL  *string `json:"audioUrl,omitempty"`
	StreamURL *string `json:"streamUrl,omitempty"`
	ImageURL  *string `json:"imageUrl,omitempty"`
}

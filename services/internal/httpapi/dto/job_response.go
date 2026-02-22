package dto

import "github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"

type Track struct {
	ID          string  `json:"id"`
	JobID       string  `json:"job_id"`
	SunoAudioID string  `json:"suno_audio_id"`
	Title       string  `json:"title"`
	Tags        *string `json:"tags,omitempty"`

	DurationSec float64 `json:"duration_sec"`

	AudioURL  string  `json:"audio_url"`
	StreamURL *string `json:"stream_url,omitempty"`
	ImageURL  *string `json:"image_url,omitempty"`

	IsFavorite bool   `json:"is_favorite"`
	CreatedAt  string `json:"created_at"` // RFC3339
}

type Job struct {
	ID         string           `json:"id"`
	Status     domain.JobStatus `json:"status"`
	SunoTaskID *string          `json:"suno_task_id,omitempty"`

	Tracks []Track `json:"tracks,omitempty"`
	Error  *string `json:"error,omitempty"`

	CreatedAt string `json:"created_at"` // RFC3339
	UpdatedAt string `json:"updated_at"` // RFC3339
}

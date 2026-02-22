package dto

import (
	"time"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
)

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
	ID     string `json:"id"`
	Status string `json:"status"` // queued|processing|ready|failed

	// params
	Prompt       string  `json:"prompt"`
	CustomMode   bool    `json:"custom_mode"`
	Style        *string `json:"style,omitempty"`
	Title        *string `json:"title,omitempty"`
	Instrumental bool    `json:"instrumental"`
	Model        string  `json:"model"`                  // "V4"|"V4_5"|...
	VocalGender  *string `json:"vocal_gender,omitempty"` // "m"|"f"
	NegativeTags *string `json:"negative_tags,omitempty"`

	Tracks []Track `json:"tracks,omitempty"`
	Error  *string `json:"error,omitempty"`

	CreatedAt string `json:"created_at"` // RFC3339
	UpdatedAt string `json:"updated_at"` // RFC3339
}

// NewTrack — mapper domain.Track -> dto.Track
func NewTrack(t domain.Track) Track {
	return Track{
		ID:          t.ID.String(),
		JobID:       t.JobID.String(),
		SunoAudioID: t.SunoAudioID,
		Title:       t.Title,
		Tags:        t.Tags,

		DurationSec: t.DurationSec,

		AudioURL:  t.AudioURL,
		StreamURL: t.StreamURL,
		ImageURL:  t.ImageURL,

		IsFavorite: t.IsFavorite,
		CreatedAt:  t.CreatedAt.Format(time.RFC3339),
	}
}

// NewJob — mapper domain.Job -> dto.Job
func NewJob(j domain.Job) Job {
	tracks := make([]Track, 0, len(j.Tracks))
	for _, t := range j.Tracks {
		tracks = append(tracks, NewTrack(t))
	}

	var vocal *string
	if j.Params.VocalGender != nil {
		v := j.Params.VocalGender.String()
		vocal = &v
	}

	return Job{
		ID:     j.ID.String(),
		Status: j.Status.String(),

		Prompt:       j.Params.Prompt,
		CustomMode:   j.Params.CustomMode,
		Style:        j.Params.Style,
		Title:        j.Params.Title,
		Instrumental: j.Params.Instrumental,
		Model:        j.Params.Model.String(),
		VocalGender:  vocal,
		NegativeTags: j.Params.NegativeTags,

		Tracks: tracks,
		Error:  j.Error,

		CreatedAt: j.CreatedAt.Format(time.RFC3339),
		UpdatedAt: j.UpdatedAt.Format(time.RFC3339),
	}
}

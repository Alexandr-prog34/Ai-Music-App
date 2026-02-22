package dto

import "github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"

// CreateJobRequest — запрос от Flutter на создание job.
type CreateJobRequest struct {
	Prompt       string              `json:"prompt"`
	CustomMode   bool                `json:"custom_mode"`
	Style        *string             `json:"style,omitempty"`
	Title        *string             `json:"title,omitempty"`
	Instrumental bool                `json:"instrumental"`
	Model        domain.SunoModel    `json:"model,omitempty"`        // V4 | V4_5 | V4_5PLUS | V4_5ALL | V5
	VocalGender  *domain.VocalGender `json:"vocal_gender,omitempty"` // "m" | "f"
	NegativeTags *string             `json:"negative_tags,omitempty"`
}

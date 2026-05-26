package events

import "github.com/google/uuid"

const DefaultChannel = "job_updates"

type JobUpdatedEvent struct {
	Type   string    `json:"type"`
	UserID uuid.UUID `json:"user_id"`
	JobID  uuid.UUID `json:"job_id"`
}

package dto

type WSEventType string

const (
	WSEventJobUpdated WSEventType = "job_updated"
)

type WSMessage struct {
	Type    WSEventType `json:"type"`
	Payload any         `json:"payload"`
}

// Удобный тип, чтобы payload был строго Job.
type WSJobUpdated struct {
	Type    WSEventType `json:"type"`
	Payload Job         `json:"payload"`
}

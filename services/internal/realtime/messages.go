package realtime

import "github.com/AI-Music-App001/Ai-Music-Generator/services/internal/view"

type WSEventType string

const (
	WSEventJobUpdated WSEventType = "job_updated"
	WSEventPong       WSEventType = "pong"
	WSEventError      WSEventType = "error"
)

type WSPong struct {
	Type WSEventType `json:"type"`
}

type WSError struct {
	Type    WSEventType `json:"type"`
	Message string      `json:"message"`
}

type WSJobUpdated struct {
	Type WSEventType `json:"type"`
	Data view.Job    `json:"data"`
}

type WSClientEventType string

const (
	WSClientEventPing WSClientEventType = "ping"
)

type WSClientMessage struct {
	Type WSClientEventType `json:"type"`
}

func NewWSPong() WSPong {
	return WSPong{Type: WSEventPong}
}

func NewWSJobUpdated(job view.Job) WSJobUpdated {
	return WSJobUpdated{
		Type: WSEventJobUpdated,
		Data: job,
	}
}

func NewWSError(msg string) WSError {
	return WSError{
		Type:    WSEventError,
		Message: msg,
	}
}

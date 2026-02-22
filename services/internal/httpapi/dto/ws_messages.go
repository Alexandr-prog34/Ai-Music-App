package dto

// --- Server -> Client events ---

type WSEventType string

const (
	WSEventJobUpdated WSEventType = "job_updated"
	WSEventPong       WSEventType = "pong"
	WSEventError      WSEventType = "error"
)

// WSPong is sent by server as a response to client ping (health-check).
type WSPong struct {
	Type WSEventType `json:"type"`
}

// WSError is sent to the client when a server-side error occurs.
type WSError struct {
	Type    WSEventType `json:"type"`
	Message string      `json:"message"`
}

// WSJobUpdated is sent when job status or tracks changed.
type WSJobUpdated struct {
	Type    WSEventType `json:"type"`
	Payload Job         `json:"payload"`
}

// --- Client -> Server events ---

type WSClientEventType string

const (
	WSClientEventPing WSClientEventType = "ping"
)

// WSClientMessage is a message sent from the client to the server.
type WSClientMessage struct {
	Type WSClientEventType `json:"type"`
}

// --- Constructors (helpers) ---

// NewWSPong returns a WSPong response.
func NewWSPong() WSPong {
	return WSPong{Type: WSEventPong}
}

// NewWSJobUpdated returns a WSJobUpdated message for the given job.
func NewWSJobUpdated(job Job) WSJobUpdated {
	return WSJobUpdated{
		Type:    WSEventJobUpdated,
		Payload: job,
	}
}

// NewWSError returns a WSError message with the given error text.
func NewWSError(msg string) WSError {
	return WSError{
		Type:    WSEventError,
		Message: msg,
	}
}

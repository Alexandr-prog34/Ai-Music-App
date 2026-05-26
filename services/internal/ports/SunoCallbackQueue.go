package ports

import (
	"context"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/sunocallback"
)

type SunoCallbackMessage struct {
	Request  sunocallback.Request
	Attempts int
	Receipt  string
}

type SunoCallbackQueue interface {
	Enqueue(ctx context.Context, req sunocallback.Request) error
	Dequeue(ctx context.Context) (SunoCallbackMessage, error)
	Ack(ctx context.Context, msg SunoCallbackMessage) error
	Retry(ctx context.Context, msg SunoCallbackMessage) error
	Recover(ctx context.Context) error
}

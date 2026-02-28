package ports

import (
	"context"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/google/uuid"
)

// Notifier — абстракция для пуш-уведомлений (WS сейчас, потом FCM/APNs и т.д.)
type Notifier interface {
	JobUpdated(ctx context.Context, installID uuid.UUID, job domain.Job) error
}

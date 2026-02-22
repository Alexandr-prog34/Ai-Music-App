package ports

import (
	"github.com/google/uuid"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
)

// Notifier — абстракция для пуш-уведомлений (WS сейчас, потом можно и FCM и т.д.)
type Notifier interface {
	JobUpdated(userID uuid.UUID, job domain.Job) error
}

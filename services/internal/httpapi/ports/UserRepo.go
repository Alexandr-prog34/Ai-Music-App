package ports

import (
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/google/uuid"
)

// UserRepo — интерфейс репозитория пользователей.
type UserRepo interface {
	// GetOrCreateUser — получить пользователя по install_id или создать нового.
	GetOrCreateUser(installID uuid.UUID) (domain.User, error)
}

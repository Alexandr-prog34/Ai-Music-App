package ports

import "github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"

// UserRepo — интерфейс репозитория пользователей.
type UserRepo interface {
	// GetOrCreateUser — получить пользователя по install_id или создать нового.
	GetOrCreateUser(installID string) (domain.User, error)
}

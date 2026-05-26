package ports

import (
	"context"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/google/uuid"
)

type UserRepository interface {
	// GetOrCreateUser — получить пользователя по install_id или создать нового.
	GetOrCreateUser(ctx context.Context, installID uuid.UUID) (domain.User, error)
}

package domain

import (
	"time"

	"github.com/google/uuid"
)

// User — анонимный пользователь, привязанный к install_id (генерится на клиенте и хранится локально).
type User struct {
	ID        uuid.UUID
	InstallID uuid.UUID
	CreatedAt time.Time
}

func (u User) Validate() error {
	if u.ID == uuid.Nil {
		return InvalidInput(ErrUserIDRequired)
	}
	if u.InstallID == uuid.Nil {
		return InvalidInput(ErrUserInstallIDRequired)
	}
	return nil
}

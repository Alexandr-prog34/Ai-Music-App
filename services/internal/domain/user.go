package domain

import (
	"errors"
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
		return errors.New("user.id is required")
	}
	if u.InstallID == uuid.Nil {
		return errors.New("user.install_id is required")
	}
	return nil
}

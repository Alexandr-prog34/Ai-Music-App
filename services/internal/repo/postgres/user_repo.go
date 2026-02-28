package postgres

import (
	"context"
	"database/sql"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/google/uuid"
)

type UserRepo struct {
	db *sql.DB
}

func NewUserRepo(db *sql.DB) *UserRepo {
	return &UserRepo{db: db}
}

func (r *UserRepo) GetOrCreateUser(ctx context.Context, installID uuid.UUID) (domain.User, error) {
	var u domain.User
	err := r.db.QueryRowContext(ctx, qUserGetOrCreate, uuid.New(), installID).
		Scan(&u.ID, &u.InstallID, &u.CreatedAt)
	return u, err
}

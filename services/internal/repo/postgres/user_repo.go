package postgres

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type UserRepo struct {
	db *sqlx.DB
}

func NewUserRepo(db *sql.DB) ports.UserRepository {
	return &UserRepo{db: sqlx.NewDb(db, "pgx")}
}

func (r *UserRepo) GetOrCreateUser(ctx context.Context, installID uuid.UUID) (domain.User, error) {
	var u domain.User
	err := r.db.QueryRowxContext(ctx, qUserGetOrCreate, installID).
		Scan(&u.ID, &u.InstallID, &u.CreatedAt)
	if err != nil {
		return domain.User{}, fmt.Errorf("get or create user: %w", err)
	}
	return u, nil
}

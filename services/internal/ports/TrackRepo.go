package ports

import (
	"context"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/google/uuid"
)

type TrackRepository interface {
	CreateTrack(ctx context.Context, track domain.Track) (domain.Track, error)

	GetTrack(ctx context.Context, id uuid.UUID) (domain.Track, error)
	ListTracksByJobID(ctx context.Context, jobID uuid.UUID) ([]domain.Track, error)
	DeleteTrack(ctx context.Context, id uuid.UUID, userID uuid.UUID) error

	// ListTracks — по контракту (пагинация + фильтр избранного).
	// favorite=nil -> не фильтровать, favorite!=nil -> фильтр по значению
	// Возвращаем также total для пагинации
	ListTracks(ctx context.Context, userID uuid.UUID, favorite *bool, limit, offset int) ([]domain.Track, int, error)

	SetFavorite(ctx context.Context, id uuid.UUID, userID uuid.UUID, favorite bool) error
}

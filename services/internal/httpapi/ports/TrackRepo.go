package ports

import (
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/google/uuid"
)

type TrackRepo interface {
	CreateTrack(track domain.Track) (domain.Track, error)

	GetTrackbyJobId(jobId uuid.UUID) ([]domain.Track, error)
}

package ports

import "github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"

type TrackRepo interface {
	CreateTrack(track domain.Track) (domain.Track, error)

	GetTrackbyJobId(jobId string) ([]domain.Track, error)
}

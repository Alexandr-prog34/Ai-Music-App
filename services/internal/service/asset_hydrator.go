package service

import (
	"context"
	"time"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
)

const assetURLTTL = 15 * time.Minute

type AssetHydrator struct {
	storage ports.ObjectStorage
}

func NewAssetHydrator(storage ports.ObjectStorage) *AssetHydrator {
	return &AssetHydrator{storage: storage}
}

func (h *AssetHydrator) HydrateTrack(ctx context.Context, track domain.Track) (domain.Track, error) {
	if h == nil || h.storage == nil {
		return track, nil
	}

	if track.AudioBucket != "" && track.AudioKey != "" {
		audioURL, err := h.storage.PresignGetURL(ctx, track.AudioBucket, track.AudioKey, assetURLTTL)
		if err != nil {
			return domain.Track{}, err
		}
		track.AudioURL = audioURL
		if track.StreamURL == nil {
			track.StreamURL = &audioURL
		}
	}

	if track.ImageBucket != nil && track.ImageKey != nil && *track.ImageBucket != "" && *track.ImageKey != "" {
		imageURL, err := h.storage.PresignGetURL(ctx, *track.ImageBucket, *track.ImageKey, assetURLTTL)
		if err != nil {
			return domain.Track{}, err
		}
		track.ImageURL = &imageURL
	}

	return track, nil
}

func (h *AssetHydrator) HydrateTracks(ctx context.Context, tracks []domain.Track) ([]domain.Track, error) {
	if len(tracks) == 0 {
		return tracks, nil
	}

	out := make([]domain.Track, 0, len(tracks))
	for _, track := range tracks {
		hydrated, err := h.HydrateTrack(ctx, track)
		if err != nil {
			return nil, err
		}
		out = append(out, hydrated)
	}
	return out, nil
}

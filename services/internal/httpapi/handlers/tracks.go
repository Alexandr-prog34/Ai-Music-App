package handlers

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"

	"github.com/google/uuid"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/view"
)

type TrackService interface {
	ListTracks(ctx context.Context, installID uuid.UUID, favorite *bool, limit, offset int) ([]domain.Track, int, error)
	GetTrack(ctx context.Context, installID uuid.UUID, trackID uuid.UUID) (domain.Track, error)
	DeleteTrack(ctx context.Context, installID uuid.UUID, trackID uuid.UUID) error
	SetFavorite(ctx context.Context, installID uuid.UUID, trackID uuid.UUID, favorite bool) error
	DownloadTrackURL(ctx context.Context, installID uuid.UUID, trackID uuid.UUID) (string, error)
}

type ListTracksHandler struct {
	svc    TrackService
	logger *slog.Logger
}

func NewListTracksHandler(svc TrackService, logger *slog.Logger) *ListTracksHandler {
	if logger == nil {
		logger = slog.Default()
	}
	return &ListTracksHandler{svc: svc, logger: logger}
}

func (h *ListTracksHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	deviceID, err := deviceIDFromRequest(r)
	if err != nil {
		writeRequestError(w, err)
		return
	}

	favorite, err := parseFavorite(r.URL.Query().Get("favorite"))
	if err != nil {
		writeBadRequest(w, err.Error())
		return
	}
	limit, offset, err := parseLimitOffset(r)
	if err != nil {
		writeBadRequest(w, err.Error())
		return
	}

	tracks, total, err := h.svc.ListTracks(r.Context(), deviceID, favorite, limit, offset)
	if err != nil {
		writeError(w, err, h.logger)
		return
	}

	items := make([]view.Track, 0, len(tracks))
	for _, track := range tracks {
		items = append(items, view.NewTrack(track))
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(map[string]any{
		"items": items,
		"total": total,
	}); err != nil {
		h.logger.Error("failed to encode tracks list response", "err", err)
	}
}

type GetTrackHandler struct {
	svc    TrackService
	logger *slog.Logger
}

func NewGetTrackHandler(svc TrackService, logger *slog.Logger) *GetTrackHandler {
	if logger == nil {
		logger = slog.Default()
	}
	return &GetTrackHandler{svc: svc, logger: logger}
}

func (h *GetTrackHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	deviceID, err := deviceIDFromRequest(r)
	if err != nil {
		writeRequestError(w, err)
		return
	}

	trackID, err := uuidPathValue(r, "id")
	if err != nil {
		writeBadRequest(w, "invalid track id")
		return
	}

	track, err := h.svc.GetTrack(r.Context(), deviceID, trackID)
	if err != nil {
		writeError(w, err, h.logger)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(view.NewTrack(track)); err != nil {
		h.logger.Error("failed to encode get track response", "err", err, "track_id", trackID.String())
	}
}

type DeleteTrackHandler struct {
	svc    TrackService
	logger *slog.Logger
}

func NewDeleteTrackHandler(svc TrackService, logger *slog.Logger) *DeleteTrackHandler {
	if logger == nil {
		logger = slog.Default()
	}
	return &DeleteTrackHandler{svc: svc, logger: logger}
}

func (h *DeleteTrackHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	deviceID, err := deviceIDFromRequest(r)
	if err != nil {
		writeRequestError(w, err)
		return
	}

	trackID, err := uuidPathValue(r, "id")
	if err != nil {
		writeBadRequest(w, "invalid track id")
		return
	}

	if err := h.svc.DeleteTrack(r.Context(), deviceID, trackID); err != nil {
		writeError(w, err, h.logger)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

type FavoriteTrackHandler struct {
	svc      TrackService
	favorite bool
	logger   *slog.Logger
}

func NewFavoriteTrackHandler(svc TrackService, favorite bool, logger *slog.Logger) *FavoriteTrackHandler {
	if logger == nil {
		logger = slog.Default()
	}
	return &FavoriteTrackHandler{svc: svc, favorite: favorite, logger: logger}
}

func (h *FavoriteTrackHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	deviceID, err := deviceIDFromRequest(r)
	if err != nil {
		writeRequestError(w, err)
		return
	}

	trackID, err := uuidPathValue(r, "id")
	if err != nil {
		writeBadRequest(w, "invalid track id")
		return
	}

	if err := h.svc.SetFavorite(r.Context(), deviceID, trackID, h.favorite); err != nil {
		writeError(w, err, h.logger)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

type DownloadTrackHandler struct {
	svc    TrackService
	logger *slog.Logger
}

func NewDownloadTrackHandler(svc TrackService, logger *slog.Logger) *DownloadTrackHandler {
	if logger == nil {
		logger = slog.Default()
	}
	return &DownloadTrackHandler{svc: svc, logger: logger}
}

func (h *DownloadTrackHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	deviceID, err := deviceIDFromRequest(r)
	if err != nil {
		writeRequestError(w, err)
		return
	}

	trackID, err := uuidPathValue(r, "id")
	if err != nil {
		writeBadRequest(w, "invalid track id")
		return
	}

	downloadURL, err := h.svc.DownloadTrackURL(r.Context(), deviceID, trackID)
	if err != nil {
		writeError(w, err, h.logger)
		return
	}

	http.Redirect(w, r, downloadURL, http.StatusFound)
}

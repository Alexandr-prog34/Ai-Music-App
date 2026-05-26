package handlers

import (
	"log/slog"
	"net/http"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/realtime"
)

type WSHandler struct {
	userRepo ports.UserRepository
	hub      *realtime.Hub
	logger   *slog.Logger
}

func NewWSHandler(userRepo ports.UserRepository, hub *realtime.Hub, logger *slog.Logger) *WSHandler {
	if logger == nil {
		logger = slog.Default()
	}
	return &WSHandler{
		userRepo: userRepo,
		hub:      hub,
		logger:   logger,
	}
}

func (h *WSHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	deviceID, err := wsDeviceIDFromRequest(r)
	if err != nil {
		writeRequestError(w, err)
		return
	}

	user, err := h.userRepo.GetOrCreateUser(r.Context(), deviceID)
	if err != nil {
		writeError(w, err, h.logger)
		return
	}

	if err := h.hub.ServeWS(w, r, user.ID); err != nil {
		h.logger.Error("failed to serve websocket", "err", err, "user_id", user.ID.String())
	}
}

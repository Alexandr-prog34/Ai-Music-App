package handlers

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/suno"
)

// SunoCallbackHandler — HTTP обработчик callback'ов от Suno.
type SunoCallbackHandler struct {
	logger *slog.Logger
}

// NewSunoCallbackHandler — конструктор.
func NewSunoCallbackHandler(logger *slog.Logger) *SunoCallbackHandler {
	if logger == nil {
		logger = slog.Default()
	}
	return &SunoCallbackHandler{logger: logger}
}

// ServeHTTP — POST callback от Suno.
func (h *SunoCallbackHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	defer r.Body.Close()

	var req suno.SunoCallbackRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid json: "+err.Error(), http.StatusBadRequest)
		return
	}

	// handlers/errors.go НЕ знает про suno, поэтому suno ошибки маппим тут локально
	if err := req.Validate(); err != nil {
		if errors.Is(err, suno.ErrInvalidCallback) {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		writeError(w, err, h.logger)
		return
	}

	// TODO: здесь будет обработка callback (обновить job, сохранить tracks, уведомить)
	w.WriteHeader(http.StatusOK)
}
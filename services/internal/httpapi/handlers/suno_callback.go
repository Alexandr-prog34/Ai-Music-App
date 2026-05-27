package handlers

import (
	"context"
	"crypto/subtle"
	"errors"
	"log/slog"
	"net/http"
	"encoding/json"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/sunocallback"
)

const sunoCallbackSecretHeader = "X-Suno-Callback-Secret"

// SunoCallbackHandler — HTTP обработчик callback'ов от Suno.
type SunoCallbackHandler struct {
	logger *slog.Logger
	secret string // SUNO_CALLBACK_SECRET из конфига
	queue  sunoCallbackQueue
}

type sunoCallbackQueue interface {
	Enqueue(ctx context.Context, req sunocallback.Request) error
}

// NewSunoCallbackHandler — конструктор.
func NewSunoCallbackHandler(secret string, queue sunoCallbackQueue, logger *slog.Logger) *SunoCallbackHandler {
	if logger == nil {
		logger = slog.Default()
	}
	return &SunoCallbackHandler{
		logger: logger,
		secret: secret,
		queue:  queue,
	}
}

// ServeHTTP — POST callback от Suno.
func (h *SunoCallbackHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeMethodNotAllowed(w)
		return
	}
	defer r.Body.Close()

	// Защита от подделки callback: проверяем секрет из конфига
	if h.secret == "" {
		h.logger.Error("SUNO_CALLBACK_SECRET is empty")
		writeAPIError(w, http.StatusInternalServerError, "internal_error", "internal error")
		return
	}
	gotToken := r.URL.Query().Get("token")
	gotHeader := r.Header.Get(sunoCallbackSecretHeader)
	if subtle.ConstantTimeCompare([]byte(gotToken), []byte(h.secret)) != 1 &&
		subtle.ConstantTimeCompare([]byte(gotHeader), []byte(h.secret)) != 1 {
		writeUnauthorized(w, "unauthorized", "unauthorized")
		return
	}

	var req sunocallback.Request
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeBadRequest(w, "invalid json: "+err.Error())
		return
	}

	// handlers/errors.go НЕ знает про callback contract, поэтому эти ошибки маппим тут локально
	if err := req.Validate(); err != nil {
		if errors.Is(err, sunocallback.ErrInvalidCallback) {
			writeBadRequest(w, err.Error())
			return
		}
		writeError(w, err, h.logger)
		return
	}

	if h.queue == nil {
		writeServiceUnavailable(w, "callback queue unavailable")
		return
	}
	if err := h.queue.Enqueue(r.Context(), req); err != nil {
		writeError(w, err, h.logger)
		return
	}

	writeJSON(w, http.StatusOK, statusResponse{Status: "received"})
}

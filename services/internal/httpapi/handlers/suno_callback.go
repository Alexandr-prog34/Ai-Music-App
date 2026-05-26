package handlers

import (
	"crypto/subtle"
	"errors"
	"log/slog"
	"net/http"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/suno"
)

const sunoCallbackSecretHeader = "X-Suno-Callback-Secret"

// SunoCallbackHandler — HTTP обработчик callback'ов от Suno.
type SunoCallbackHandler struct {
	logger *slog.Logger
	secret string // SUNO_CALLBACK_SECRET из конфига
}

// NewSunoCallbackHandler — конструктор.
func NewSunoCallbackHandler(secret string, logger *slog.Logger) *SunoCallbackHandler {
	if logger == nil {
		logger = slog.Default()
	}
	return &SunoCallbackHandler{
		logger: logger,
		secret: secret,
	}
}

// ServeHTTP — POST callback от Suno.
func (h *SunoCallbackHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	defer r.Body.Close()

	// Защита от подделки callback: проверяем секрет из конфига
	if h.secret == "" {
		h.logger.Error("SUNO_CALLBACK_SECRET is empty")
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	got := r.Header.Get(sunoCallbackSecretHeader)
	if subtle.ConstantTimeCompare([]byte(got), []byte(h.secret)) != 1 {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req suno.SunoCallbackRequest
	if err := decodeJSONBody(w, r, maxSunoCallbackBodySize, &req); err != nil {
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

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := writeJSON(w, map[string]string{"status": "received"}); err != nil {
		h.logger.Error("failed to encode callback response", "err", err)
	}
}

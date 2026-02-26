package handlers

import (
	"errors"
	"log/slog"
	"net/http"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
)

// writeError — единый хелпер для ответа с ошибкой.
func writeError(w http.ResponseWriter, err error, log *slog.Logger) {
	if log == nil {
		log = slog.Default()
	}

	switch {
	// 404: not found
	case errors.Is(err, domain.ErrJobNotFound),
		errors.Is(err, domain.ErrTrackNotFound):
		http.Error(w, err.Error(), http.StatusNotFound)
		return

	// 400: invalid input / validation
	case errors.Is(err, domain.ErrInvalidInput),
		errors.Is(err, domain.ErrModelInvalid),
		errors.Is(err, domain.ErrVocalGenderInvalid):
		http.Error(w, err.Error(), http.StatusBadRequest)
		return

	// 409: конфликт (например неверный переход статуса)
	case errors.Is(err, domain.ErrInvalidStatusTransition):
		http.Error(w, err.Error(), http.StatusConflict)
		return

	// Всё остальное — 500
	default:
		log.Error("unexpected error", "err", err)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
}
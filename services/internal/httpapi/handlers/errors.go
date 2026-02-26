package handlers

import (
	"errors"
	"net/http"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/suno"
)

// writeError — единый хелпер для ответа с ошибкой.
// Делает switch-case по sentinel-категориям ошибок (они уже сделаны у нас).
func writeError(w http.ResponseWriter, err error) {
	switch {
	// HTTP 400: доменная валидация входных данных
	case errors.Is(err, domain.ErrInvalidInput):
		http.Error(w, err.Error(), http.StatusBadRequest)
		return

	// HTTP 400: некорректный callback от Suno
	case errors.Is(err, suno.ErrInvalidCallback):
		http.Error(w, err.Error(), http.StatusBadRequest)
		return

	// Всё остальное — 500
	default:
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
}
package handlers

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"strings"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
)

type errorResponse struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

type statusResponse struct {
	Status  string `json:"status"`
	Message string `json:"message,omitempty"`
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(payload); err != nil {
		slog.Default().Error("failed to encode json response", "err", err, "status", status)
	}
}

func writeAPIError(w http.ResponseWriter, status int, code string, message string) {
	code = strings.TrimSpace(code)
	if code == "" {
		code = "error"
	}
	message = strings.TrimSpace(message)
	if message == "" {
		message = http.StatusText(status)
	}
	writeJSON(w, status, errorResponse{
		Code:    code,
		Message: message,
	})
}

func writeBadRequest(w http.ResponseWriter, message string) {
	writeAPIError(w, http.StatusBadRequest, "bad_request", message)
}

func writeUnauthorized(w http.ResponseWriter, code string, message string) {
	if strings.TrimSpace(code) == "" {
		code = "unauthorized"
	}
	writeAPIError(w, http.StatusUnauthorized, code, message)
}

func writeMethodNotAllowed(w http.ResponseWriter) {
	writeAPIError(w, http.StatusMethodNotAllowed, "method_not_allowed", "method not allowed")
}

func writeServiceUnavailable(w http.ResponseWriter, message string) {
	writeAPIError(w, http.StatusServiceUnavailable, "service_unavailable", message)
}

func writeRequestError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, errDeviceIDMissing), errors.Is(err, errWSDeviceIDMissing):
		writeUnauthorized(w, "device_missing", err.Error())
	default:
		writeBadRequest(w, err.Error())
	}
}

// writeError — единый хелпер для ответа с ошибкой.
func writeError(w http.ResponseWriter, err error, log *slog.Logger) {
	if log == nil {
		log = slog.Default()
	}

	switch {
	// 404: not found
	case errors.Is(err, domain.ErrJobNotFound),
		errors.Is(err, domain.ErrTrackNotFound):
		writeAPIError(w, http.StatusNotFound, "not_found", err.Error())
		return

	// 400: invalid input / validation
	case errors.Is(err, domain.ErrInvalidInput),
		errors.Is(err, domain.ErrModelInvalid),
		errors.Is(err, domain.ErrVocalGenderInvalid),
		errors.Is(err, domain.ErrStatusInvalid):
		writeAPIError(w, http.StatusBadRequest, "invalid_input", err.Error())
		return

	// 409: конфликт (например неверный переход статуса)
	case errors.Is(err, domain.ErrInvalidStatusTransition):
		writeAPIError(w, http.StatusConflict, "conflict", err.Error())
		return

	// Всё остальное — 500
	default:
		log.Error("unexpected error", "err", err)
		writeAPIError(w, http.StatusInternalServerError, "internal_error", "internal error")
		return
	}
}

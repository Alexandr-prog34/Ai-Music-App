package handlers

import (
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/google/uuid"
)

var (
	errDeviceIDMissing   = errors.New("X-Device-Id is required")
	errWSDeviceIDMissing = errors.New("device_id query or X-Device-Id header is required")
)

func deviceIDFromRequest(r *http.Request) (uuid.UUID, error) {
	raw := strings.TrimSpace(r.Header.Get("X-Device-Id"))
	if raw == "" {
		return uuid.Nil, errDeviceIDMissing
	}

	deviceID, err := uuid.Parse(raw)
	if err != nil {
		return uuid.Nil, fmt.Errorf("X-Device-Id must be a valid UUID: %w", err)
	}
	return deviceID, nil
}

func wsDeviceIDFromRequest(r *http.Request) (uuid.UUID, error) {
	if raw := strings.TrimSpace(r.URL.Query().Get("device_id")); raw != "" {
		deviceID, err := uuid.Parse(raw)
		if err != nil {
			return uuid.Nil, fmt.Errorf("device_id must be a valid UUID: %w", err)
		}
		return deviceID, nil
	}

	if raw := strings.TrimSpace(r.Header.Get("X-Device-Id")); raw != "" {
		deviceID, err := uuid.Parse(raw)
		if err != nil {
			return uuid.Nil, fmt.Errorf("X-Device-Id must be a valid UUID: %w", err)
		}
		return deviceID, nil
	}

	return uuid.Nil, errWSDeviceIDMissing
}

func uuidPathValue(r *http.Request, name string) (uuid.UUID, error) {
	return uuid.Parse(strings.TrimSpace(r.PathValue(name)))
}

func parseLimitOffset(r *http.Request) (int, int, error) {
	limit := 20
	offset := 0

	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil {
			return 0, 0, errors.New("limit must be an integer")
		}
		limit = parsed
	}

	if raw := strings.TrimSpace(r.URL.Query().Get("offset")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil {
			return 0, 0, errors.New("offset must be an integer")
		}
		offset = parsed
	}

	return limit, offset, nil
}

func parseJobStatus(raw string) (*domain.JobStatus, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil
	}

	status := domain.JobStatus(raw)
	if err := status.Validate(); err != nil {
		return nil, err
	}

	return &status, nil
}

func parseFavorite(raw string) (*bool, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil
	}

	parsed, err := strconv.ParseBool(raw)
	if err != nil {
		return nil, errors.New("favorite must be a boolean")
	}
	return &parsed, nil
}

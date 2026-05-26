package httpapi_test

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/httpapi/handlers"
)

type stubJobService struct {
	createJob func(ctx context.Context, deviceID uuid.UUID, params domain.JobParams) (domain.Job, error)
}

func (s stubJobService) CreateJob(ctx context.Context, deviceID uuid.UUID, params domain.JobParams) (domain.Job, error) {
	return s.createJob(ctx, deviceID, params)
}

func TestJobsHandlerCreateJobSuccess(t *testing.T) {
	deviceID := uuid.MustParse("11111111-1111-1111-1111-111111111111")
	now := time.Date(2026, 5, 25, 12, 0, 0, 0, time.UTC)

	handler := handlers.NewJobsHandler(stubJobService{
		createJob: func(ctx context.Context, gotDeviceID uuid.UUID, params domain.JobParams) (domain.Job, error) {
			if gotDeviceID != deviceID {
				t.Fatalf("expected deviceID %s, got %s", deviceID, gotDeviceID)
			}
			if params.Prompt != "Calm piano track" {
				t.Fatalf("expected normalized prompt, got %q", params.Prompt)
			}
			if params.Model != domain.SunoModelV45All {
				t.Fatalf("expected default model %q, got %q", domain.SunoModelV45All, params.Model)
			}

			return domain.Job{
				ID:        uuid.MustParse("22222222-2222-2222-2222-222222222222"),
				UserID:    gotDeviceID,
				Status:    domain.JobQueued,
				Params:    params,
				CreatedAt: now,
				UpdatedAt: now,
			}, nil
		},
	}, nil)

	req := httptest.NewRequest(http.MethodPost, "/jobs", bytes.NewBufferString(`{"prompt":"  Calm piano track  "}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Device-Id", deviceID.String())
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusCreated, rec.Code, rec.Body.String())
	}

	var resp map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if resp["status"] != "queued" {
		t.Fatalf("expected queued status, got %#v", resp["status"])
	}
	if resp["prompt"] != "Calm piano track" {
		t.Fatalf("expected trimmed prompt, got %#v", resp["prompt"])
	}
	if resp["model"] != "V4_5ALL" {
		t.Fatalf("expected default model V4_5ALL, got %#v", resp["model"])
	}
}

func TestJobsHandlerRequiresDeviceID(t *testing.T) {
	handler := handlers.NewJobsHandler(stubJobService{
		createJob: func(ctx context.Context, deviceID uuid.UUID, params domain.JobParams) (domain.Job, error) {
			t.Fatal("service must not be called when device id is missing")
			return domain.Job{}, nil
		},
	}, nil)

	req := httptest.NewRequest(http.MethodPost, "/jobs", bytes.NewBufferString(`{"prompt":"test"}`))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "X-Device-Id is required") {
		t.Fatalf("unexpected body: %s", rec.Body.String())
	}
}

func TestJobsHandlerRejectsInvalidJSON(t *testing.T) {
	handler := handlers.NewJobsHandler(stubJobService{
		createJob: func(ctx context.Context, deviceID uuid.UUID, params domain.JobParams) (domain.Job, error) {
			t.Fatal("service must not be called for invalid json")
			return domain.Job{}, nil
		},
	}, nil)

	req := httptest.NewRequest(http.MethodPost, "/jobs", bytes.NewBufferString(`{"prompt":`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Device-Id", uuid.NewString())
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "invalid json") {
		t.Fatalf("unexpected body: %s", rec.Body.String())
	}
}

func TestJobsHandlerMapsDomainValidationErrors(t *testing.T) {
	handler := handlers.NewJobsHandler(stubJobService{
		createJob: func(ctx context.Context, deviceID uuid.UUID, params domain.JobParams) (domain.Job, error) {
			return domain.Job{}, domain.InvalidInput(domain.ErrPromptRequired)
		},
	}, nil)

	req := httptest.NewRequest(http.MethodPost, "/jobs", bytes.NewBufferString(`{"prompt":"test"}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Device-Id", uuid.NewString())
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
	if !strings.Contains(rec.Body.String(), domain.ErrPromptRequired.Error()) {
		t.Fatalf("unexpected body: %s", rec.Body.String())
	}
}

func TestJobsHandlerMapsUnexpectedErrorsTo500(t *testing.T) {
	handler := handlers.NewJobsHandler(stubJobService{
		createJob: func(ctx context.Context, deviceID uuid.UUID, params domain.JobParams) (domain.Job, error) {
			return domain.Job{}, errors.New("db is down")
		},
	}, nil)

	req := httptest.NewRequest(http.MethodPost, "/jobs", bytes.NewBufferString(`{"prompt":"test"}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Device-Id", uuid.NewString())
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("expected status %d, got %d", http.StatusInternalServerError, rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "internal error") {
		t.Fatalf("unexpected body: %s", rec.Body.String())
	}
}

package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/view"
	"github.com/google/uuid"
)

type stubJobService struct {
	gotDeviceID uuid.UUID
	gotParams   domain.JobParams
	job         domain.Job
	err         error
}

func (s *stubJobService) CreateJob(_ context.Context, deviceID uuid.UUID, params domain.JobParams) (domain.Job, error) {
	s.gotDeviceID = deviceID
	s.gotParams = params
	if s.err != nil {
		return domain.Job{}, s.err
	}
	return s.job, nil
}

func TestJobsHandlerMissingDeviceReturnsJSON401(t *testing.T) {
	handler := NewJobsHandler(&stubJobService{}, nil)
	req := httptest.NewRequest(http.MethodPost, "/jobs", strings.NewReader(`{"prompt":"test"}`))
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", rec.Code)
	}

	var resp errorResponse
	if err := json.NewDecoder(rec.Body).Decode(&resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if resp.Code != "device_missing" {
		t.Fatalf("expected device_missing code, got %q", resp.Code)
	}
}

func TestJobsHandlerLyricsModePassesCustomParams(t *testing.T) {
	svc := &stubJobService{}
	handler := NewJobsHandler(svc, nil)
	deviceID := uuid.MustParse("33333333-3333-3333-3333-333333333333")
	style := "Indie Pop"
	title := "Morning Glow"
	params := domain.JobParams{
		Prompt:       "[Verse]\nCity lights are fading slow",
		CustomMode:   true,
		Style:        &style,
		Title:        &title,
		Instrumental: false,
		Model:        domain.SunoModelV45All,
	}
	svc.job = domain.NewJob(uuid.New(), params)

	req := httptest.NewRequest(http.MethodPost, "/jobs", strings.NewReader(`{
		"prompt":"[Verse]\nCity lights are fading slow",
		"custom_mode":true,
		"style":"Indie Pop",
		"title":"Morning Glow",
		"instrumental":false,
		"model":"V4_5ALL"
	}`))
	req.Header.Set("X-Device-Id", deviceID.String())
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d: %s", rec.Code, rec.Body.String())
	}
	if svc.gotDeviceID != deviceID {
		t.Fatalf("unexpected device id passed to service: %s", svc.gotDeviceID.String())
	}
	if !svc.gotParams.CustomMode {
		t.Fatalf("expected custom mode to be true")
	}
	if svc.gotParams.Style == nil || *svc.gotParams.Style != style {
		t.Fatalf("unexpected style passed to service: %#v", svc.gotParams.Style)
	}
	if svc.gotParams.Title == nil || *svc.gotParams.Title != title {
		t.Fatalf("unexpected title passed to service: %#v", svc.gotParams.Title)
	}

	var resp view.Job
	if err := json.NewDecoder(rec.Body).Decode(&resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if !resp.CustomMode {
		t.Fatalf("expected response custom_mode=true")
	}
}

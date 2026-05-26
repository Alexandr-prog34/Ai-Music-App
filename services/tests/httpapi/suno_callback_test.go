package httpapi_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/httpapi/handlers"
)

func TestSunoCallbackHandlerRejectsWrongMethod(t *testing.T) {
	handler := handlers.NewSunoCallbackHandler("change-me", nil)
	req := httptest.NewRequest(http.MethodGet, "/suno/callback", nil)
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("expected status %d, got %d", http.StatusMethodNotAllowed, rec.Code)
	}
}

func TestSunoCallbackHandlerRejectsInvalidSecret(t *testing.T) {
	handler := handlers.NewSunoCallbackHandler("change-me", nil)
	req := httptest.NewRequest(http.MethodPost, "/suno/callback", bytes.NewBufferString(`{"taskId":"task-1","callbackType":"text"}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Suno-Callback-Secret", "wrong")
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected status %d, got %d", http.StatusUnauthorized, rec.Code)
	}
}

func TestSunoCallbackHandlerRejectsInvalidPayload(t *testing.T) {
	handler := handlers.NewSunoCallbackHandler("change-me", nil)
	req := httptest.NewRequest(http.MethodPost, "/suno/callback", bytes.NewBufferString(`{"callbackType":"complete"}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Suno-Callback-Secret", "change-me")
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "taskId is required") {
		t.Fatalf("unexpected body: %s", rec.Body.String())
	}
}

func TestSunoCallbackHandlerSuccess(t *testing.T) {
	handler := handlers.NewSunoCallbackHandler("change-me", nil)
	req := httptest.NewRequest(http.MethodPost, "/suno/callback", bytes.NewBufferString(`{"taskId":"task-1","callbackType":"text"}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Suno-Callback-Secret", "change-me")
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}

	var resp map[string]string
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if resp["status"] != "received" {
		t.Fatalf("expected received status, got %#v", resp["status"])
	}
}

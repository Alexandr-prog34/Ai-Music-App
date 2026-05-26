package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/sunocallback"
)

type stubSunoCallbackQueue struct {
	called bool
	req    sunocallback.Request
	err    error
}

func (s *stubSunoCallbackQueue) Enqueue(_ context.Context, req sunocallback.Request) error {
	s.called = true
	s.req = req
	return s.err
}

func TestSunoCallbackHandlerAcceptsTokenQuery(t *testing.T) {
	queue := &stubSunoCallbackQueue{}
	handler := NewSunoCallbackHandler("secret", queue, nil)
	req := httptest.NewRequest(http.MethodPost, "/internal/suno/callback?token=secret", strings.NewReader(`{
		"code":200,
		"msg":"ok",
		"data":{
			"callbackType":"complete",
			"task_id":"task-1",
			"data":[{"id":"audio-1","audio_url":"https://example.com/audio.mp3","duration":123.4}]
		}
	}`))
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
	if !queue.called {
		t.Fatalf("expected callback queue to be called")
	}
	if queue.req.TaskID() != "task-1" {
		t.Fatalf("unexpected task id %q", queue.req.TaskID())
	}

	var resp statusResponse
	if err := json.NewDecoder(rec.Body).Decode(&resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if resp.Status != "received" {
		t.Fatalf("expected received status, got %q", resp.Status)
	}
}

func TestSunoCallbackHandlerRejectsMissingSecret(t *testing.T) {
	handler := NewSunoCallbackHandler("secret", &stubSunoCallbackQueue{}, nil)
	req := httptest.NewRequest(http.MethodPost, "/internal/suno/callback", strings.NewReader(`{"code":200,"msg":"ok","data":{"callbackType":"text","task_id":"task-1"}}`))
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", rec.Code)
	}

	var resp errorResponse
	if err := json.NewDecoder(rec.Body).Decode(&resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if resp.Code != "unauthorized" {
		t.Fatalf("expected unauthorized code, got %q", resp.Code)
	}
}

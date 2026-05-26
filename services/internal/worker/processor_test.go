package worker

import (
	"testing"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/sunocallback"
)

func TestCallbackRequestFromDetailsSuccess(t *testing.T) {
	duration := 123.4
	details := ports.GenerationDetails{
		Status: "SUCCESS",
		Results: []sunocallback.Result{
			{
				AudioID:     "audio-1",
				AudioURL:    stringPtr("https://example.com/audio.mp3"),
				DurationSec: &duration,
			},
		},
	}

	req, done := callbackRequestFromDetails("task-1", details)
	if !done {
		t.Fatalf("expected success status to resolve polling")
	}
	if req.Data.CallbackType != sunocallback.TypeComplete {
		t.Fatalf("expected complete callback type, got %q", req.Data.CallbackType)
	}
	if req.Data.TaskID != "task-1" {
		t.Fatalf("unexpected task id %q", req.Data.TaskID)
	}
}

func TestCallbackRequestFromDetailsError(t *testing.T) {
	req, done := callbackRequestFromDetails("task-2", ports.GenerationDetails{
		Status:       "GENERATE_AUDIO_FAILED",
		ErrorMessage: "generation failed",
	})
	if !done {
		t.Fatalf("expected error status to resolve polling")
	}
	if req.Data.CallbackType != sunocallback.TypeError {
		t.Fatalf("expected error callback type, got %q", req.Data.CallbackType)
	}
	if req.Message != "generation failed" {
		t.Fatalf("unexpected message %q", req.Message)
	}
}

func TestCallbackRequestFromDetailsPending(t *testing.T) {
	_, done := callbackRequestFromDetails("task-3", ports.GenerationDetails{Status: "PENDING"})
	if done {
		t.Fatalf("expected pending status to keep polling")
	}
}

func stringPtr(value string) *string {
	return &value
}

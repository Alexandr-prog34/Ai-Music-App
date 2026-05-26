package handlers

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestWSDeviceIDFromRequestAcceptsQueryParam(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/ws?device_id=11111111-1111-1111-1111-111111111111", nil)

	deviceID, err := wsDeviceIDFromRequest(req)
	if err != nil {
		t.Fatalf("expected query device id to be accepted, got %v", err)
	}
	if deviceID.String() != "11111111-1111-1111-1111-111111111111" {
		t.Fatalf("unexpected device id %s", deviceID.String())
	}
}

func TestWSDeviceIDFromRequestFallsBackToHeader(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/ws", nil)
	req.Header.Set("X-Device-Id", "22222222-2222-2222-2222-222222222222")

	deviceID, err := wsDeviceIDFromRequest(req)
	if err != nil {
		t.Fatalf("expected header device id to be accepted, got %v", err)
	}
	if deviceID.String() != "22222222-2222-2222-2222-222222222222" {
		t.Fatalf("unexpected device id %s", deviceID.String())
	}
}

func TestDeviceIDFromRequestMissingReturnsTypedError(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/jobs", nil)

	_, err := deviceIDFromRequest(req)
	if !errors.Is(err, errDeviceIDMissing) {
		t.Fatalf("expected errDeviceIDMissing, got %v", err)
	}
}

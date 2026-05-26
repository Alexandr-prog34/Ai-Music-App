package handlers

import (
	"encoding/json"
	"net/http"
)

func writeJSON(w http.ResponseWriter, v any) error {
	return json.NewEncoder(w).Encode(v)
}

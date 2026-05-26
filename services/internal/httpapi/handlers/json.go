package handlers

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
)

const (
	maxCreateJobBodySize    int64 = 64 * 1024
	maxSunoCallbackBodySize int64 = 128 * 1024
)

func decodeJSONBody(w http.ResponseWriter, r *http.Request, maxBodySize int64, dst any) error {
	r.Body = http.MaxBytesReader(w, r.Body, maxBodySize)

	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()

	if err := dec.Decode(dst); err != nil {
		var syntaxErr *json.SyntaxError
		var unmarshalTypeErr *json.UnmarshalTypeError
		var maxBytesErr *http.MaxBytesError

		switch {
		case errors.As(err, &syntaxErr):
			return fmt.Errorf("invalid json at position %d", syntaxErr.Offset)
		case errors.Is(err, io.EOF):
			return errors.New("request body must not be empty")
		case errors.As(err, &unmarshalTypeErr):
			if unmarshalTypeErr.Field != "" {
				return fmt.Errorf("invalid value for field %q", unmarshalTypeErr.Field)
			}
			return errors.New("invalid json value")
		case errors.As(err, &maxBytesErr):
			return fmt.Errorf("request body too large (max %d bytes)", maxBodySize)
		default:
			return err
		}
	}

	if dec.More() {
		return errors.New("request body must contain only one json object")
	}

	return nil
}

package suno

import (
	"errors"
	"fmt"
)

var (
	// Категория: некорректный входящий callback (HTTP 400)
	ErrInvalidCallback = errors.New("invalid callback")

	// Причины
	ErrTaskIDRequired             = errors.New("taskId is required")
	ErrCallbackTypeInvalid        = errors.New("unknown callbackType")
	ErrResultsRequiredForComplete = errors.New("results required for complete callback")
	ErrErrorMessageRequired       = errors.New("errorMessage required for error callback")
)

func InvalidCallback(cause error, detailsFmt ...any) error {
	if len(detailsFmt) == 0 {
		return fmt.Errorf("%w: %w", ErrInvalidCallback, cause)
	}

	format, ok := detailsFmt[0].(string)
	if !ok {
		return fmt.Errorf("%w: %w", ErrInvalidCallback, cause)
	}
	args := detailsFmt[1:]

	details := fmt.Sprintf(format, args...)
	return fmt.Errorf("%w: %w (%s)", ErrInvalidCallback, cause, details)
}

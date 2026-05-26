package sunocallback

import (
	"errors"
	"fmt"
)

var (
	ErrInvalidCallback = errors.New("invalid callback")

	ErrTaskIDRequired             = errors.New("task_id is required")
	ErrCallbackTypeInvalid        = errors.New("unknown callbackType")
	ErrResultsRequiredForComplete = errors.New("results required for complete callback")
	ErrMessageRequired            = errors.New("msg is required")
)

func Invalid(cause error, detailsFmt ...any) error {
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

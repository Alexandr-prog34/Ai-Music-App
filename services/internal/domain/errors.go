package domain

import (
	"errors"
	"fmt"
)

var (
	// Категория (HTTP 400)
	ErrInvalidInput = errors.New("invalid input")
)

// Причины — чтобы ловить через errors.Is(err, ErrXxx)

var (
	// Enums / common
	ErrModelRequired       = errors.New("model is required")
	ErrModelInvalid        = errors.New("model is invalid")
	ErrVocalGenderRequired = errors.New("vocal_gender is required")
	ErrVocalGenderInvalid  = errors.New("vocal_gender is invalid")
	ErrStatusRequired      = errors.New("status is required")
	ErrStatusInvalid       = errors.New("status is invalid")

	// JobParams
	ErrPromptRequired = errors.New("prompt is required")
	ErrPromptTooLong  = errors.New("prompt is too long")

	ErrStyleRequiredCustom = errors.New("style is required when custom_mode=true")
	ErrStyleTooLong        = errors.New("style is too long")

	ErrTitleRequiredCustom = errors.New("title is required when custom_mode=true")
	ErrTitleTooLong        = errors.New("title is too long")

	ErrStyleMustBeEmptyNonCustom        = errors.New("style must be empty when custom_mode=false")
	ErrTitleMustBeEmptyNonCustom        = errors.New("title must be empty when custom_mode=false")
	ErrNegativeTagsMustBeEmptyNonCustom = errors.New("negative_tags must be empty when custom_mode=false")
	ErrVocalGenderMustBeEmptyNonCustom  = errors.New("vocal_gender must be empty when custom_mode=false")

	ErrVocalGenderNotAllowedInstrumental = errors.New("vocal_gender must be empty when instrumental=true")
	ErrNegativeTagsTooLong               = errors.New("negative_tags is too long")
	// Not found (HTTP 404)
	ErrJobNotFound   = errors.New("job not found")
	ErrTrackNotFound = errors.New("track not found")

	// Job transitions
	ErrInvalidStatusTransition = errors.New("invalid status transition")

	// Track
	ErrTrackIDRequired       = errors.New("track.id is required")
	ErrTrackJobIDRequired    = errors.New("track.job_id is required")
	ErrTrackSunoAudioIDReq   = errors.New("track.suno_audio_id is required")
	ErrTrackTitleRequired    = errors.New("track.title is required")
	ErrTrackAudioURLRequired = errors.New("track.audio_url is required")

	// User
	ErrUserIDRequired        = errors.New("user.id is required")
	ErrUserInstallIDRequired = errors.New("user.install_id is required")
)

// InvalidInput — общий конструктор ошибок валидации.
// Делает wrap и категории, и причины, чтобы:
//
//	errors.Is(err, ErrInvalidInput) == true
//	errors.Is(err, ErrPromptRequired) == true
func InvalidInput(cause error, detailsFmt ...any) error {
	if len(detailsFmt) == 0 {
		return fmt.Errorf("%w: %w", ErrInvalidInput, cause)
	}

	format, ok := detailsFmt[0].(string)
	if !ok {
		return fmt.Errorf("%w: %w", ErrInvalidInput, cause)
	}
	args := detailsFmt[1:]

	details := fmt.Sprintf(format, args...)
	return fmt.Errorf("%w: %w (%s)", ErrInvalidInput, cause, details)
}

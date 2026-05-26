package domain

import (
	"errors"
	"strings"
	"testing"
)

func TestJobParamsValidateRejectsCustomFieldsInNonCustomMode(t *testing.T) {
	style := "Indie Pop"
	params := JobParams{
		Prompt:     "sunrise over the city",
		CustomMode: false,
		Style:      &style,
		Model:      SunoModelV45All,
	}
	params.Normalize()

	err := params.Validate()
	if !errors.Is(err, ErrStyleMustBeEmptyNonCustom) {
		t.Fatalf("expected ErrStyleMustBeEmptyNonCustom, got %v", err)
	}
}

func TestJobParamsValidateLyricsModeRequiresStyleAndTitle(t *testing.T) {
	params := JobParams{
		Prompt:       "[Verse]\nCity lights are fading slow",
		CustomMode:   true,
		Instrumental: false,
		Model:        SunoModelV45All,
	}
	params.Normalize()

	err := params.Validate()
	if !errors.Is(err, ErrStyleRequiredCustom) {
		t.Fatalf("expected ErrStyleRequiredCustom, got %v", err)
	}

	style := "Indie Pop"
	title := "Morning Glow"
	params.Style = &style
	params.Title = &title
	if err := params.Validate(); err != nil {
		t.Fatalf("expected valid lyrics mode payload, got %v", err)
	}
}

func TestJobParamsValidateEnforcesNonCustomPromptLimit(t *testing.T) {
	params := JobParams{
		Prompt: strings.Repeat("a", 501),
		Model:  SunoModelV45All,
	}
	params.Normalize()

	err := params.Validate()
	if !errors.Is(err, ErrPromptTooLong) {
		t.Fatalf("expected ErrPromptTooLong, got %v", err)
	}
}

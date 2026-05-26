package domain_test

import (
	"errors"
	"strings"
	"testing"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
)

func TestJobParamsNormalizeSetsDefaultsAndTrims(t *testing.T) {
	style := "   "
	title := "  Night Drive  "
	negativeTags := "  noise  "

	params := domain.JobParams{
		Prompt:       "  synthwave  ",
		Style:        &style,
		Title:        &title,
		NegativeTags: &negativeTags,
	}

	params.Normalize()

	if params.Prompt != "synthwave" {
		t.Fatalf("expected prompt to be trimmed, got %q", params.Prompt)
	}
	if params.Style != nil {
		t.Fatalf("expected empty style to become nil")
	}
	if params.Title == nil || *params.Title != "Night Drive" {
		t.Fatalf("expected title to be trimmed, got %#v", params.Title)
	}
	if params.NegativeTags == nil || *params.NegativeTags != "noise" {
		t.Fatalf("expected negative tags to be trimmed, got %#v", params.NegativeTags)
	}
	if params.Model != domain.SunoModelV45All {
		t.Fatalf("expected default model %q, got %q", domain.SunoModelV45All, params.Model)
	}
}

func TestJobParamsValidateNonCustomSuccess(t *testing.T) {
	params := domain.JobParams{
		Prompt:       "Calm piano for studying",
		Instrumental: true,
		Model:        domain.SunoModelV45All,
	}

	if err := params.Validate(); err != nil {
		t.Fatalf("expected valid params, got %v", err)
	}
}

func TestJobParamsValidateCustomRequiresStyleAndTitle(t *testing.T) {
	params := domain.JobParams{
		Prompt:     "Night city lights",
		CustomMode: true,
		Model:      domain.SunoModelV5,
	}

	err := params.Validate()
	if !errors.Is(err, domain.ErrStyleRequiredCustom) {
		t.Fatalf("expected style-required error, got %v", err)
	}

	style := "Electronic Pop"
	params.Style = &style
	err = params.Validate()
	if !errors.Is(err, domain.ErrTitleRequiredCustom) {
		t.Fatalf("expected title-required error, got %v", err)
	}
}

func TestJobParamsValidateRejectsForbiddenFieldsForNonCustom(t *testing.T) {
	style := "rock"
	params := domain.JobParams{
		Prompt: "test prompt",
		Model:  domain.SunoModelV45All,
		Style:  &style,
	}

	err := params.Validate()
	if !errors.Is(err, domain.ErrStyleMustBeEmptyNonCustom) {
		t.Fatalf("expected non-custom style error, got %v", err)
	}
}

func TestJobParamsValidateRejectsVocalGenderForInstrumental(t *testing.T) {
	vocalGender := domain.VocalFemale
	params := domain.JobParams{
		Prompt:       "cinematic pads",
		Model:        domain.SunoModelV45All,
		Instrumental: true,
		VocalGender:  &vocalGender,
		CustomMode:   true,
	}
	style := "Ambient"
	title := "Arrival"
	params.Style = &style
	params.Title = &title

	err := params.Validate()
	if !errors.Is(err, domain.ErrVocalGenderNotAllowedInstrumental) {
		t.Fatalf("expected vocal gender / instrumental error, got %v", err)
	}
}

func TestJobParamsValidateRejectsTooLongPromptInNonCustomMode(t *testing.T) {
	params := domain.JobParams{
		Prompt: strings.Repeat("a", 501),
		Model:  domain.SunoModelV45All,
	}

	err := params.Validate()
	if !errors.Is(err, domain.ErrPromptTooLong) {
		t.Fatalf("expected prompt-too-long error, got %v", err)
	}
}

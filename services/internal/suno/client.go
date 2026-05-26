package suno

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
	"crypto/tls"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/sunocallback"
	"github.com/google/uuid"
)

const (
	defaultMode      = "dev"
	defaultBaseURL   = "https://api.sunoapi.org"
	defaultTimeout   = 15 * time.Second
	generateEndpoint = "/api/v1/generate"
	detailsEndpoint  = "/api/v1/generate/record-info"
)

type ClientConfig struct {
	Mode    string
	BaseURL string
	APIKey  string
	Timeout time.Duration
}

type Client struct {
	mode       string
	baseURL    string
	apiKey     string
	httpClient *http.Client
}

type APIError struct {
	HTTPStatus int
	Code       int
	Message    string
}

func (e *APIError) Error() string {
	msg := strings.TrimSpace(e.Message)
	switch {
	case e.Code != 0 && msg != "":
		return fmt.Sprintf("suno request rejected: code=%d msg=%s", e.Code, msg)
	case e.Code != 0:
		return fmt.Sprintf("suno request rejected: code=%d", e.Code)
	case e.HTTPStatus != 0 && msg != "":
		return fmt.Sprintf("suno request rejected: status=%d msg=%s", e.HTTPStatus, msg)
	case e.HTTPStatus != 0:
		return fmt.Sprintf("suno request rejected: status=%d", e.HTTPStatus)
	default:
		return "suno request rejected"
	}
}

func (e *APIError) Retryable() bool {
	switch e.Code {
	case 400, 401, 404, 413, 429:
		return false
	case 405, 430, 455, 500:
		return true
	}

	if e.HTTPStatus >= 500 {
		return true
	}
	if e.HTTPStatus >= 400 && e.HTTPStatus < 500 {
		return false
	}

	return true
}

func NewClient(cfg ClientConfig) *Client {
	mode := strings.TrimSpace(cfg.Mode)
	if mode == "" {
		mode = defaultMode
	}

	baseURL := strings.TrimRight(strings.TrimSpace(cfg.BaseURL), "/")
	if baseURL == "" {
		baseURL = defaultBaseURL
	}

	timeout := cfg.Timeout
	if timeout <= 0 {
		timeout = defaultTimeout
	}

	return &Client{
		mode:    mode,
		baseURL: baseURL,
		apiKey:  strings.TrimSpace(cfg.APIKey),
		httpClient: &http.Client{
			Timeout: timeout,

			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{
					InsecureSkipVerify: true,
				},
			},
		},
	}
}

type generateRequest struct {
	Prompt       string  `json:"prompt"`
	CustomMode   bool    `json:"customMode"`
	Style        *string `json:"style,omitempty"`
	Title        *string `json:"title,omitempty"`
	Instrumental bool    `json:"instrumental"`
	Model        string  `json:"model,omitempty"`
	VocalGender  *string `json:"vocalGender,omitempty"`
	NegativeTags *string `json:"negativeTags,omitempty"`
	CallbackURL  string  `json:"callBackUrl"`
}

type generateResponse struct {
	Code int    `json:"code"`
	Msg  string `json:"msg"`
	Data struct {
		TaskID string `json:"taskId"`
	} `json:"data"`
}

type generationDetailsResponse struct {
	Code int    `json:"code"`
	Msg  string `json:"msg"`
	Data struct {
		Status       string  `json:"status"`
		ErrorMessage *string `json:"errorMessage"`
		Response     struct {
			SunoData []generationDetailsTrack `json:"sunoData"`
		} `json:"response"`
	} `json:"data"`
}

type generationDetailsTrack struct {
	AudioID        string   `json:"id"`
	AudioURL       *string  `json:"audioUrl,omitempty"`
	StreamAudioURL *string  `json:"streamAudioUrl,omitempty"`
	ImageURL       *string  `json:"imageUrl,omitempty"`
	Prompt         *string  `json:"prompt,omitempty"`
	ModelName      *string  `json:"modelName,omitempty"`
	Title          *string  `json:"title,omitempty"`
	Tags           *string  `json:"tags,omitempty"`
	DurationSec    *float64 `json:"duration,omitempty"`
}

func (c *Client) GenerateMusic(params domain.JobParams, callbackURL string) (string, error) {
	if strings.EqualFold(c.mode, defaultMode) {
		return buildDevTaskID(params, callbackURL), nil
	}
	if c.apiKey == "" {
		return "", fmt.Errorf("suno api key is empty")
	}

	reqBody := buildGenerateRequest(params, callbackURL)
	payload, err := json.Marshal(reqBody)
	if err != nil {
		return "", fmt.Errorf("marshal suno request: %w", err)
	}

	req, err := http.NewRequest(http.MethodPost, c.baseURL+generateEndpoint, bytes.NewReader(payload))
	if err != nil {
		return "", fmt.Errorf("build suno request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	if c.apiKey != "" {
		req.Header.Set("Authorization", "Bearer "+c.apiKey)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("suno request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		return "", &APIError{
			HTTPStatus: resp.StatusCode,
			Message:    strings.TrimSpace(string(body)),
		}
	}

	var decoded generateResponse
	if err := json.NewDecoder(resp.Body).Decode(&decoded); err != nil {
		return "", fmt.Errorf("decode suno response: %w", err)
	}
	if decoded.Code != 200 {
		return "", &APIError{
			HTTPStatus: resp.StatusCode,
			Code:       decoded.Code,
			Message:    decoded.Msg,
		}
	}
	taskID := strings.TrimSpace(decoded.Data.TaskID)
	if taskID == "" {
		return "", fmt.Errorf("decode suno response: empty taskId")
	}

	return taskID, nil
}

func (c *Client) GetGenerationDetails(ctx context.Context, taskID string) (ports.GenerationDetails, error) {
	if strings.EqualFold(c.mode, defaultMode) {
		return ports.GenerationDetails{}, fmt.Errorf("suno generation details are unavailable in dev mode")
	}
	if c.apiKey == "" {
		return ports.GenerationDetails{}, fmt.Errorf("suno api key is empty")
	}

	endpoint, err := url.Parse(c.baseURL + detailsEndpoint)
	if err != nil {
		return ports.GenerationDetails{}, fmt.Errorf("build suno details request: %w", err)
	}

	query := endpoint.Query()
	query.Set("taskId", strings.TrimSpace(taskID))
	endpoint.RawQuery = query.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint.String(), nil)
	if err != nil {
		return ports.GenerationDetails{}, fmt.Errorf("build suno details request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+c.apiKey)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return ports.GenerationDetails{}, fmt.Errorf("suno details request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		return ports.GenerationDetails{}, &APIError{
			HTTPStatus: resp.StatusCode,
			Message:    strings.TrimSpace(string(body)),
		}
	}

	var decoded generationDetailsResponse
	if err := json.NewDecoder(resp.Body).Decode(&decoded); err != nil {
		return ports.GenerationDetails{}, fmt.Errorf("decode suno details response: %w", err)
	}
	if decoded.Code != 200 {
		return ports.GenerationDetails{}, &APIError{
			HTTPStatus: resp.StatusCode,
			Code:       decoded.Code,
			Message:    decoded.Msg,
		}
	}

	results := make([]sunocallback.Result, 0, len(decoded.Data.Response.SunoData))
	for _, item := range decoded.Data.Response.SunoData {
		results = append(results, sunocallback.Result{
			AudioID:        item.AudioID,
			AudioURL:       item.AudioURL,
			StreamAudioURL: item.StreamAudioURL,
			ImageURL:       item.ImageURL,
			Prompt:         item.Prompt,
			ModelName:      item.ModelName,
			Title:          item.Title,
			Tags:           item.Tags,
			DurationSec:    item.DurationSec,
		})
	}

	return ports.GenerationDetails{
		Status:       strings.ToUpper(strings.TrimSpace(decoded.Data.Status)),
		ErrorMessage: stringValue(decoded.Data.ErrorMessage),
		Results:      results,
	}, nil
}

func buildGenerateRequest(params domain.JobParams, callbackURL string) generateRequest {
	var vocalGender *string
	if params.VocalGender != nil {
		v := params.VocalGender.String()
		vocalGender = &v
	}

	return generateRequest{
		Prompt:       params.Prompt,
		CustomMode:   params.CustomMode,
		Style:        params.Style,
		Title:        params.Title,
		Instrumental: params.Instrumental,
		Model:        params.Model.String(),
		VocalGender:  vocalGender,
		NegativeTags: params.NegativeTags,
		CallbackURL:  callbackURL,
	}
}

func buildDevTaskID(params domain.JobParams, callbackURL string) string {
	return "dev-" + uuid.NewString()
}

func stringValue(raw *string) string {
	if raw == nil {
		return ""
	}
	return strings.TrimSpace(*raw)
}

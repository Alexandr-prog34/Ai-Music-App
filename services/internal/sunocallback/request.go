package sunocallback

import "strings"

type Type string

const (
	TypeText     Type = "text"
	TypeFirst    Type = "first"
	TypeComplete Type = "complete"
	TypeError    Type = "error"
)

func (t Type) isValid() bool {
	switch t {
	case TypeText, TypeFirst, TypeComplete, TypeError:
		return true
	default:
		return false
	}
}

type Request struct {
	Code    int    `json:"code"`
	Message string `json:"msg"`
	Data    Data   `json:"data"`
}

func (r Request) Validate() error {
	if strings.TrimSpace(r.Message) == "" {
		return Invalid(ErrMessageRequired)
	}

	if strings.TrimSpace(r.Data.TaskID) == "" {
		return Invalid(ErrTaskIDRequired)
	}

	if !r.Data.CallbackType.isValid() {
		return Invalid(ErrCallbackTypeInvalid, "got=%q", string(r.Data.CallbackType))
	}

	if r.Data.CallbackType == TypeComplete && len(r.Data.Results) == 0 {
		return Invalid(ErrResultsRequiredForComplete)
	}

	return nil
}

func (r Request) TaskID() string {
	return strings.TrimSpace(r.Data.TaskID)
}

func (r Request) CallbackType() Type {
	return r.Data.CallbackType
}

func (r Request) Results() []Result {
	return r.Data.Results
}

func (r Request) ErrorMessage() string {
	return strings.TrimSpace(r.Message)
}

type Data struct {
	CallbackType Type     `json:"callbackType"`
	TaskID       string   `json:"task_id"`
	Results      []Result `json:"data,omitempty"`
}

type Result struct {
	AudioID              string   `json:"id"`
	AudioURL             *string  `json:"audio_url,omitempty"`
	SourceAudioURL       *string  `json:"source_audio_url,omitempty"`
	StreamAudioURL       *string  `json:"stream_audio_url,omitempty"`
	SourceStreamAudioURL *string  `json:"source_stream_audio_url,omitempty"`
	ImageURL             *string  `json:"image_url,omitempty"`
	SourceImageURL       *string  `json:"source_image_url,omitempty"`
	Prompt               *string  `json:"prompt,omitempty"`
	ModelName            *string  `json:"model_name,omitempty"`
	Title                *string  `json:"title,omitempty"`
	Tags                 *string  `json:"tags,omitempty"`
	CreateTime           *string  `json:"createTime,omitempty"`
	DurationSec          *float64 `json:"duration,omitempty"`
}

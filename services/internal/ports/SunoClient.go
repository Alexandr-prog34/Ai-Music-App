package ports

import (
	"context"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/sunocallback"
)

type GenerationDetails struct {
	Status       string
	ErrorMessage string
	Results      []sunocallback.Result
}

// SunoClient — интерфейс для работы с API Suno.
type SunoClient interface {
	// GenerateMusic — отправить запрос на создание музыки.
	GenerateMusic(params domain.JobParams, callbackURL string) (string, error) // возвращаем taskId
	GetGenerationDetails(ctx context.Context, taskID string) (GenerationDetails, error)
}

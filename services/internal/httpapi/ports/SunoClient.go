package ports

import "github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"

// SunoClient — интерфейс для работы с API Suno.
type SunoClient interface {
	// GenerateMusic — отправить запрос на создание музыки.
	GenerateMusic(params domain.JobParams, callbackURL string) (string, error) // возвращаем taskId
}

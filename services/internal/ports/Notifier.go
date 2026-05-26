package ports

import (
	"context"

	"github.com/google/uuid"
)

// Notifier публикует изменение job так, чтобы API мог доставить обновление клиентам.
type Notifier interface {
	JobUpdated(ctx context.Context, userID uuid.UUID, jobID uuid.UUID) error
}

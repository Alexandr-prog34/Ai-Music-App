package domain

import (
	"time"

	"github.com/google/uuid"
)

// NewJob — доменный конструктор job.
// Здесь фиксируем инварианты создания (ID, статус, timestamps).
// deviceID пока кладём в UserID, потому что в домене поле так называется.
func NewJob(userID uuid.UUID, params JobParams) Job {
	now := time.Now().UTC()

	return Job{
		ID:        uuid.New(),
		UserID:    userID,
		Status:    JobQueued,
		Params:    params,
		CreatedAt: now,
		UpdatedAt: now,
	}
}

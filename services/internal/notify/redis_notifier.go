package notify

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/events"
	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
)

type RedisNotifier struct {
	client  *redis.Client
	channel string
}

func NewRedisNotifier(client *redis.Client, channel string) ports.Notifier {
	channel = strings.TrimSpace(channel)
	if channel == "" {
		channel = events.DefaultChannel
	}

	return &RedisNotifier{
		client:  client,
		channel: channel,
	}
}

func (n *RedisNotifier) JobUpdated(ctx context.Context, userID uuid.UUID, jobID uuid.UUID) error {
	event := events.JobUpdatedEvent{
		Type:   "job_updated",
		UserID: userID,
		JobID:  jobID,
	}
	payload, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("marshal notifier event: %w", err)
	}

	if err := n.client.Publish(ctx, n.channel, payload).Err(); err != nil {
		return fmt.Errorf("publish notifier event: %w", err)
	}
	return nil
}

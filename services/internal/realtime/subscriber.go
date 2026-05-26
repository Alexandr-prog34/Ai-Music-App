package realtime

import (
	"context"
	"encoding/json"
	"log/slog"
	"strings"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/events"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/view"
	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

type JobLookup interface {
	GetJobForUser(ctx context.Context, userID uuid.UUID, jobID uuid.UUID) (domain.Job, error)
}

type Subscriber struct {
	pubsub *redis.PubSub
	hub    *Hub
	lookup JobLookup
	logger *slog.Logger
}

func NewSubscriber(client *redis.Client, channel string, hub *Hub, lookup JobLookup, logger *slog.Logger) *Subscriber {
	if logger == nil {
		logger = slog.Default()
	}
	channel = strings.TrimSpace(channel)
	if channel == "" {
		channel = events.DefaultChannel
	}

	return &Subscriber{
		pubsub: client.Subscribe(context.Background(), channel),
		hub:    hub,
		lookup: lookup,
		logger: logger,
	}
}

func (s *Subscriber) Run(ctx context.Context) error {
	defer s.pubsub.Close()

	ch := s.pubsub.Channel()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case msg, ok := <-ch:
			if !ok {
				return nil
			}
			if err := s.handleMessage(ctx, msg.Payload); err != nil {
				s.logger.Error("job update subscriber failed", "err", err)
			}
		}
	}
}

func (s *Subscriber) handleMessage(ctx context.Context, payload string) error {
	var event events.JobUpdatedEvent
	if err := json.Unmarshal([]byte(payload), &event); err != nil {
		return err
	}

	job, err := s.lookup.GetJobForUser(ctx, event.UserID, event.JobID)
	if err != nil {
		return err
	}

	s.hub.BroadcastJobUpdated(event.UserID, view.NewJob(job))
	return nil
}

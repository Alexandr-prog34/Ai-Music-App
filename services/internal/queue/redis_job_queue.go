package queue

import (
	"context"
	"encoding/json"
	"log/slog"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
)

const defaultMaxQueueAttempts = 10

type jobQueuePayload struct {
	JobID    string `json:"job_id"`
	Attempts int    `json:"attempts"`
}

// RedisJobQueue реализует ports.JobQueue поверх Redis LIST с processing/DLQ.
type RedisJobQueue struct {
	client        *redis.Client
	key           string
	processingKey string
	dlqKey        string
	logger        *slog.Logger
	maxAttempts   int
}

func NewRedisJobQueue(client *redis.Client, key string, logger *slog.Logger) ports.JobQueue {
	if logger == nil {
		logger = slog.Default()
	}

	return &RedisJobQueue{
		client:        client,
		key:           key,
		processingKey: key + ":processing",
		dlqKey:        key + ":dlq",
		logger:        logger,
		maxAttempts:   defaultMaxQueueAttempts,
	}
}

func (q *RedisJobQueue) EnqueueJob(ctx context.Context, jobID uuid.UUID) error {
	if jobID == uuid.Nil {
		return ErrJobIDEmpty
	}

	raw, err := marshalJobPayload(jobQueuePayload{JobID: jobID.String()})
	if err != nil {
		return err
	}

	if err := q.client.RPush(ctx, q.key, raw).Err(); err != nil {
		return err
	}

	q.logQueueLength(ctx, q.key, "job enqueued", "job_id", jobID.String())
	return nil
}

func (q *RedisJobQueue) DequeueJob(ctx context.Context) (ports.JobMessage, error) {
	raw, err := q.client.BRPopLPush(ctx, q.key, q.processingKey, 0).Result()
	if err != nil {
		return ports.JobMessage{}, err
	}

	payload, id, err := parseJobPayload(raw)
	if err != nil {
		return ports.JobMessage{}, err
	}

	q.logQueueLength(ctx, q.processingKey, "job reserved", "job_id", id.String(), "attempts", payload.Attempts)

	return ports.JobMessage{
		ID:       id,
		Attempts: payload.Attempts,
		Receipt:  raw,
	}, nil
}

func (q *RedisJobQueue) AckJob(ctx context.Context, msg ports.JobMessage) error {
	return ackMessage(ctx, q.client, q.processingKey, msg.Receipt)
}

func (q *RedisJobQueue) RetryJob(ctx context.Context, msg ports.JobMessage) error {
	if err := ackMessage(ctx, q.client, q.processingKey, msg.Receipt); err != nil {
		return err
	}

	payload := jobQueuePayload{
		JobID:    msg.ID.String(),
		Attempts: msg.Attempts + 1,
	}
	raw, err := marshalJobPayload(payload)
	if err != nil {
		return err
	}

	target := q.key
	if payload.Attempts >= q.maxAttempts {
		target = q.dlqKey
	}

	if err := q.client.RPush(ctx, target, raw).Err(); err != nil {
		return err
	}

	if target == q.dlqKey {
		q.logger.Error("job moved to dlq", "job_id", msg.ID.String(), "attempts", payload.Attempts, "queue", q.dlqKey)
		return ports.ErrMessageMovedToDLQ
	}

	q.logger.Warn("job requeued", "job_id", msg.ID.String(), "attempts", payload.Attempts, "queue", q.key)
	return nil
}

func (q *RedisJobQueue) Recover(ctx context.Context) error {
	for {
		raw, err := q.client.RPopLPush(ctx, q.processingKey, q.key).Result()
		if err == redis.Nil {
			return nil
		}
		if err != nil {
			return err
		}

		payload, id, parseErr := parseJobPayload(raw)
		if parseErr != nil {
			return parseErr
		}

		q.logger.Warn("recovered job from processing queue", "job_id", id.String(), "attempts", payload.Attempts)
	}
}

func parseJobPayload(raw string) (jobQueuePayload, uuid.UUID, error) {
	if raw == "" {
		return jobQueuePayload{}, uuid.Nil, ErrQueuePayloadEmpty
	}

	var payload jobQueuePayload
	if err := json.Unmarshal([]byte(raw), &payload); err != nil {
		return jobQueuePayload{}, uuid.Nil, err
	}

	id, err := uuid.Parse(payload.JobID)
	if err != nil {
		return jobQueuePayload{}, uuid.Nil, err
	}

	return payload, id, nil
}

func marshalJobPayload(payload jobQueuePayload) (string, error) {
	raw, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}
	return string(raw), nil
}

func ackMessage(ctx context.Context, client *redis.Client, key string, receipt string) error {
	removed, err := client.LRem(ctx, key, 1, receipt).Result()
	if err != nil {
		return err
	}
	if removed == 0 {
		return ErrQueueAckFailed
	}
	return nil
}

func (q *RedisJobQueue) logQueueLength(ctx context.Context, key string, msg string, args ...any) {
	length, err := q.client.LLen(ctx, key).Result()
	if err != nil {
		return
	}
	args = append(args, "queue", key, "length", length)
	q.logger.Debug(msg, args...)
}

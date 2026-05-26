package queue

import (
	"context"
	"encoding/json"
	"log/slog"

	"github.com/redis/go-redis/v9"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/sunocallback"
)

type callbackQueuePayload struct {
	Request  sunocallback.Request `json:"request"`
	Attempts int                  `json:"attempts"`
}

type RedisSunoCallbackQueue struct {
	client        *redis.Client
	key           string
	processingKey string
	dlqKey        string
	logger        *slog.Logger
	maxAttempts   int
}

func NewRedisSunoCallbackQueue(client *redis.Client, key string, logger *slog.Logger) ports.SunoCallbackQueue {
	if logger == nil {
		logger = slog.Default()
	}

	return &RedisSunoCallbackQueue{
		client:        client,
		key:           key,
		processingKey: key + ":processing",
		dlqKey:        key + ":dlq",
		logger:        logger,
		maxAttempts:   defaultMaxQueueAttempts,
	}
}

func (q *RedisSunoCallbackQueue) Enqueue(ctx context.Context, req sunocallback.Request) error {
	raw, err := marshalCallbackPayload(callbackQueuePayload{Request: req})
	if err != nil {
		return err
	}

	if err := q.client.RPush(ctx, q.key, raw).Err(); err != nil {
		return err
	}

	q.logQueueLength(ctx, q.key, "suno callback enqueued", "task_id", req.TaskID())
	return nil
}

func (q *RedisSunoCallbackQueue) Dequeue(ctx context.Context) (ports.SunoCallbackMessage, error) {
	raw, err := q.client.BRPopLPush(ctx, q.key, q.processingKey, 0).Result()
	if err != nil {
		return ports.SunoCallbackMessage{}, err
	}

	payload, err := parseCallbackPayload(raw)
	if err != nil {
		return ports.SunoCallbackMessage{}, err
	}

	q.logQueueLength(ctx, q.processingKey, "suno callback reserved", "task_id", payload.Request.TaskID(), "attempts", payload.Attempts)

	return ports.SunoCallbackMessage{
		Request:  payload.Request,
		Attempts: payload.Attempts,
		Receipt:  raw,
	}, nil
}

func (q *RedisSunoCallbackQueue) Ack(ctx context.Context, msg ports.SunoCallbackMessage) error {
	return ackMessage(ctx, q.client, q.processingKey, msg.Receipt)
}

func (q *RedisSunoCallbackQueue) Retry(ctx context.Context, msg ports.SunoCallbackMessage) error {
	if err := ackMessage(ctx, q.client, q.processingKey, msg.Receipt); err != nil {
		return err
	}

	payload := callbackQueuePayload{
		Request:  msg.Request,
		Attempts: msg.Attempts + 1,
	}
	raw, err := marshalCallbackPayload(payload)
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
		q.logger.Error("suno callback moved to dlq", "task_id", msg.Request.TaskID(), "attempts", payload.Attempts, "queue", q.dlqKey)
		return ports.ErrMessageMovedToDLQ
	}

	q.logger.Warn("suno callback requeued", "task_id", msg.Request.TaskID(), "attempts", payload.Attempts, "queue", q.key)
	return nil
}

func (q *RedisSunoCallbackQueue) Recover(ctx context.Context) error {
	for {
		raw, err := q.client.RPopLPush(ctx, q.processingKey, q.key).Result()
		if err == redis.Nil {
			return nil
		}
		if err != nil {
			return err
		}

		payload, parseErr := parseCallbackPayload(raw)
		if parseErr != nil {
			return parseErr
		}

		q.logger.Warn("recovered callback from processing queue", "task_id", payload.Request.TaskID(), "attempts", payload.Attempts)
	}
}

func parseCallbackPayload(raw string) (callbackQueuePayload, error) {
	if raw == "" {
		return callbackQueuePayload{}, ErrQueuePayloadEmpty
	}

	var payload callbackQueuePayload
	if err := json.Unmarshal([]byte(raw), &payload); err != nil {
		return callbackQueuePayload{}, err
	}

	return payload, nil
}

func marshalCallbackPayload(payload callbackQueuePayload) (string, error) {
	raw, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}
	return string(raw), nil
}

func (q *RedisSunoCallbackQueue) logQueueLength(ctx context.Context, key string, msg string, args ...any) {
	length, err := q.client.LLen(ctx, key).Result()
	if err != nil {
		return
	}
	args = append(args, "queue", key, "length", length)
	q.logger.Debug(msg, args...)
}

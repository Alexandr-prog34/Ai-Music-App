package queue

import (
	"context"
	"log/slog"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
)

// RedisJobQueue реализует ports.JobQueue поверх Redis LIST.
type RedisJobQueue struct {
	client *redis.Client
	key    string
	logger *slog.Logger
}

// NewRedisJobQueue создаёт очередь с указанным ключом в Redis.
func NewRedisJobQueue(client *redis.Client, key string, logger *slog.Logger) ports.JobQueue {
	if logger == nil {
		logger = slog.Default()
	}
	return &RedisJobQueue{
		client: client,
		key:    key,
		logger: logger,
	}
}

// EnqueueJob — кладём job_id в конец списка Redis.
func (q *RedisJobQueue) EnqueueJob(ctx context.Context, jobID uuid.UUID) error {
	if jobID == uuid.Nil {
		return ErrJobIDEmpty
	}

	if err := q.client.RPush(ctx, q.key, jobID.String()).Err(); err != nil {
		return err
	}

	// Для дебага: посмотрим, сколько элементов в очереди после добавления.
	if n, err := q.client.LLen(ctx, q.key).Result(); err == nil {
		q.logger.Debug("job enqueued", "job_id", jobID.String(), "queue", q.key, "length", n)
	}

	return nil
}

// DequeueJob — блокирующе ждём следующую job из очереди.
func (q *RedisJobQueue) DequeueJob(ctx context.Context) (uuid.UUID, error) {
	// BRPop блокирует, пока в списке не появится элемент.
	// Возвращает слайс: [key, value].
	res, err := q.client.BRPop(ctx, 0, q.key).Result()
	if err != nil {
		return uuid.Nil, err
	}
	if len(res) != 2 {
		return uuid.Nil, ErrUnexpectedBRPopResult
	}

	idStr := res[1]
	id, err := uuid.Parse(idStr)
	if err != nil {
		return uuid.Nil, err
	}

	// Для дебага: длина очереди после извлечения.
	if n, err := q.client.LLen(ctx, q.key).Result(); err == nil {
		q.logger.Debug("job dequeued", "job_id", id.String(), "queue", q.key, "length", n)
	}

	return id, nil
}
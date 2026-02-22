package queue

import (
	"context"
	"errors"
	"log"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/httpapi/ports"
)

// RedisJobQueue реализует ports.JobQueue поверх Redis LIST.
type RedisJobQueue struct {
	client *redis.Client
	key    string
}

// NewRedisJobQueue создаёт очередь с указанным ключом в Redis.
func NewRedisJobQueue(client *redis.Client, key string) ports.JobQueue {
	return &RedisJobQueue{
		client: client,
		key:    key,
	}
}

// EnqueueJob — кладём job_id в конец списка Redis.
func (q *RedisJobQueue) EnqueueJob(ctx context.Context, jobID uuid.UUID) error {
	if jobID == uuid.Nil {
		return errors.New("jobID is empty")
	}

	if err := q.client.RPush(ctx, q.key, jobID.String()).Err(); err != nil {
		return err
	}

	// Для дебага: посмотрим, сколько элементов в очереди после добавления.
	if n, err := q.client.LLen(ctx, q.key).Result(); err == nil {
		log.Printf("queue: enqueued job %s, queue=%q, length=%d", jobID, q.key, n)
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
		return uuid.Nil, errors.New("unexpected BRPOP result")
	}

	idStr := res[1]
	id, err := uuid.Parse(idStr)
	if err != nil {
		return uuid.Nil, err
	}

	// Для дебага: длина очереди после извлечения.
	if n, err := q.client.LLen(ctx, q.key).Result(); err == nil {
		log.Printf("queue: dequeued job %s, queue=%q, length=%d", id, q.key, n)
	}

	return id, nil
}
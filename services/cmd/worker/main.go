// package main

// import (
// 	"context"
// 	"log"
// 	"os"
// 	"time"

// 	"github.com/google/uuid"
// 	"github.com/redis/go-redis/v9"

// 	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/queue"
// )

// func main() {
// 	// Адрес Redis берём из ENV, по умолчанию "redis:6379" (имя сервиса в docker-compose).
// 	redisAddr := getenv("REDIS_ADDR", "redis:6379")
// 	// Ключ списка в Redis, где храним job_id. Можно переопределить через ENV.
// 	queueKey := getenv("JOB_QUEUE_KEY", "jobs")

// 	// Создаём клиента Redis.
// 	rdb := redis.NewClient(&redis.Options{
// 		Addr: redisAddr,
// 	})

// 	ctx := context.Background()

// 	// Проверим соединение.
// 	if err := rdb.Ping(ctx).Err(); err != nil {
// 		log.Fatalf("worker: redis ping failed: %v", err)
// 	}
// 	log.Printf("worker: connected to redis at %s", redisAddr)

// 	jobQueue := queue.NewRedisJobQueue(rdb, queueKey)

// 	log.Printf("worker: started, listening queue %q", queueKey)

// 	// 🔍 Гороутина для периодического дампа очереди
// 	go func() {
// 		ticker := time.NewTicker(5 * time.Second)
// 		defer ticker.Stop()

// 		for {
// 			select {
// 			case <-ctx.Done():
// 				return
// 			case <-ticker.C:
// 				n, err := rdb.LLen(ctx, queueKey).Result()
// 				if err != nil {
// 					log.Printf("worker: failed to read queue length: %v", err)
// 					continue
// 				}
// 				if n == 0 {
// 					log.Printf("worker: queue %q is empty", queueKey)
// 					continue
// 				}

// 				values, err := rdb.LRange(ctx, queueKey, 0, -1).Result()
// 				if err != nil {
// 					log.Printf("worker: failed to dump queue %q: %v", queueKey, err)
// 					continue
// 				}

// 				log.Printf("worker: current queue %q (len=%d): %v", queueKey, n, values)
// 			}
// 		}
// 	}()

// 	// Основной цикл воркера.
// 	for {
// 		jobID, err := jobQueue.DequeueJob(ctx)
// 		if err != nil {
// 			log.Printf("worker: failed to dequeue job: %v", err)
// 			time.Sleep(2 * time.Second)
// 			continue
// 		}

// 		processFakeJob(jobID)
// 	}
// }

// func getenv(key, def string) string {
// 	v := os.Getenv(key)
// 	if v == "" {
// 		return def
// 	}
// 	return v
// }

// // Пока просто фейковая обработка — здесь потом будет Suno, БД и т.д.
// func processFakeJob(jobID uuid.UUID) {
// 	log.Printf("worker: start processing job %s", jobID.String())
// 	time.Sleep(4 * time.Second)
// 	log.Printf("worker: finish processing job %s", jobID.String())
// }
package main

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
)

func main() {
	// Адрес Redis берём из ENV, по умолчанию "redis:6379" (имя сервиса в docker-compose).
	redisAddr := getenv("REDIS_ADDR", "redis:6379")
	// Ключ списка в Redis, где храним job_id.
	queueKey := getenv("JOB_QUEUE_KEY", "jobs")

	// Создаём клиента Redis.
	rdb := redis.NewClient(&redis.Options{
		Addr: redisAddr,
	})

	ctx := context.Background()

	// Проверим соединение.
	if err := rdb.Ping(ctx).Err(); err != nil {
		log.Fatalf("worker (watcher): redis ping failed: %v", err)
	}
	log.Printf("worker (watcher): connected to redis at %s", redisAddr)
	log.Printf("worker (watcher): watching queue %q (without consuming)", queueKey)

	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			log.Printf("worker (watcher): context cancelled, exiting")
			return

		case <-ticker.C:
			// Получаем длину очереди
			n, err := rdb.LLen(ctx, queueKey).Result()
			if err != nil {
				log.Printf("worker (watcher): failed to read queue length: %v", err)
				continue
			}

			if n == 0 {
				log.Printf("worker (watcher): queue %q is empty", queueKey)
				continue
			}

			// Получаем все элементы очереди (job_id как строки)
			values, err := rdb.LRange(ctx, queueKey, 0, -1).Result()
			if err != nil {
				log.Printf("worker (watcher): failed to dump queue %q: %v", queueKey, err)
				continue
			}

			log.Printf("worker (watcher): current queue %q (len=%d): %v", queueKey, n, values)
		}
	}
}

func getenv(key, def string) string {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	return v
}
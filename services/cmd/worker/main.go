package main

import (
	"context"
	"fmt"
	"log"
	"log/slog"
	"net"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/events"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/notify"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/queue"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/repo/postgres"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/service"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/storage"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/suno"
	workerapp "github.com/AI-Music-App001/Ai-Music-Generator/services/internal/worker"
)

func main() {
	redisAddr := getenv("REDIS_ADDR", "redis:6379")
	postgresDSN := mustEnv("POSTGRES_DSN")
	jobQueueKey := getenv("JOB_QUEUE_KEY", "jobs")
	callbackQueueKey := getenv("SUNO_CALLBACK_QUEUE_KEY", "suno_callbacks")
	notifierChannel := getenv("NOTIFIER_CHANNEL", events.DefaultChannel)
	sunoMode := getenv("SUNO_MODE", "dev")
	sunoBaseURL := getenv("SUNO_BASE_URL", "https://api.sunoapi.org")
	sunoAPIKey := os.Getenv("SUNO_API_KEY")
	logger := slog.Default()
	sunoCallbackBaseURL := callbackBaseURL(sunoMode)
	sunoCallbackSecret := mustEnv("SUNO_CALLBACK_SECRET")
	callbackURL, err := addCallbackToken(sunoCallbackBaseURL, sunoCallbackSecret)
	if err != nil {
		log.Fatalf("worker: invalid callback url: %v", err)
	}
	callbackPublic, callbackHost, err := callbackURLPublic(callbackURL)
	if err != nil {
		log.Fatalf("worker: %v", err)
	}
	pollFallbackEnabled, err := pollingFallbackEnabled(sunoMode, callbackPublic)
	if err != nil {
		log.Fatalf("worker: %v", err)
	}

	if sunoMode != "dev" && sunoAPIKey == "" {
		log.Fatal("worker: SUNO_API_KEY is empty")
	}
	if sunoMode != "dev" && !callbackPublic && !pollFallbackEnabled {
		log.Fatalf("worker: SUNO_CALLBACK_URL must be publicly reachable in %s mode or SUNO_POLL_FALLBACK=true; got internal host %q", sunoMode, callbackHost)
	}
	if sunoMode != "dev" && !callbackPublic && pollFallbackEnabled {
		logger.Warn("worker will rely on Suno polling fallback because callback URL is not publicly reachable", "callback_url", callbackURL)
	}
	pollInterval := getenvDuration("SUNO_POLL_INTERVAL", 20*time.Second)
	pollTimeout := getenvDuration("SUNO_POLL_TIMEOUT", 10*time.Minute)
	ctx := context.Background()

	rdb := redis.NewClient(&redis.Options{Addr: redisAddr})
	if err := rdb.Ping(ctx).Err(); err != nil {
		log.Fatalf("worker: redis ping failed: %v", err)
	}
	log.Printf("worker: connected to redis at %s", redisAddr)

	db, err := postgres.Open(ctx, postgresDSN, postgres.DefaultPoolConfig())
	if err != nil {
		log.Fatalf("worker: postgres open failed: %v", err)
	}
	defer db.Close()
	log.Printf("worker: connected to postgres")

	objectStorage, err := storage.NewMinIOObjectStorage(ctx, storage.Config{
		Endpoint:       mustEnv("S3_ENDPOINT"),
		PublicEndpoint: getenv("S3_PUBLIC_ENDPOINT", mustEnv("S3_ENDPOINT")),
		AccessKey:      mustEnv("S3_ACCESS_KEY"),
		SecretKey:      mustEnv("S3_SECRET_KEY"),
		Bucket:         mustEnv("S3_BUCKET"),
	})
	if err != nil {
		log.Fatalf("worker: storage init failed: %v", err)
	}

	jobQueue := queue.NewRedisJobQueue(rdb, jobQueueKey, logger)
	callbackQueue := queue.NewRedisSunoCallbackQueue(rdb, callbackQueueKey, logger)
	jobRepo := postgres.NewJobRepo(db)
	trackRepo := postgres.NewTrackRepo(db)
	notifier := notify.NewRedisNotifier(rdb, notifierChannel)
	sunoClient := suno.NewClient(suno.ClientConfig{
		Mode:    sunoMode,
		BaseURL: sunoBaseURL,
		APIKey:  sunoAPIKey,
		Timeout: 15 * time.Second,
	})
	callbackProcessor := service.NewSunoCallbackService(jobRepo, trackRepo, objectStorage, notifier, logger)
	jobProcessor := workerapp.NewJobProcessor(jobRepo, sunoClient, notifier, callbackURL, callbackQueueIfEnabled(callbackQueue, pollFallbackEnabled), pollInterval, pollTimeout, logger)
	jobConsumer := workerapp.NewConsumer(jobQueue, jobProcessor, logger)
	callbackConsumer := workerapp.NewSunoCallbackConsumer(callbackQueue, callbackProcessor, logger)

	log.Printf("worker: starting job consumer for queue %q", jobQueueKey)
	log.Printf("worker: starting callback consumer for queue %q", callbackQueueKey)
	log.Printf("worker: suno mode=%s callback_url=%s", sunoMode, callbackURL)
	go callbackConsumer.Run(ctx)
	jobConsumer.Run(ctx)
}

func getenv(key, def string) string {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	return v
}

func mustEnv(key string) string {
	value := os.Getenv(key)
	if value == "" {
		log.Fatalf("worker: %s is empty", key)
	}
	return value
}

func callbackBaseURL(sunoMode string) string {
	if strings.EqualFold(strings.TrimSpace(sunoMode), "dev") {
		return getenv("SUNO_CALLBACK_URL", "http://api:8080/internal/suno/callback")
	}
	return mustEnv("SUNO_CALLBACK_URL")
}

func addCallbackToken(raw string, secret string) (string, error) {
	parsed, err := url.Parse(raw)
	if err != nil {
		return "", err
	}

	query := parsed.Query()
	if query.Get("token") == "" {
		query.Set("token", secret)
	}
	parsed.RawQuery = query.Encode()
	return parsed.String(), nil
}

func callbackURLPublic(raw string) (bool, string, error) {
	parsed, err := url.Parse(raw)
	if err != nil {
		return false, "", fmt.Errorf("invalid SUNO_CALLBACK_URL: %w", err)
	}

	host := strings.TrimSpace(parsed.Hostname())
	if host == "" {
		return false, "", fmt.Errorf("SUNO_CALLBACK_URL host is empty")
	}

	return !isInternalOnlyHost(host), host, nil
}

func pollingFallbackEnabled(sunoMode string, callbackPublic bool) (bool, error) {
	raw := strings.TrimSpace(os.Getenv("SUNO_POLL_FALLBACK"))
	if raw == "" {
		return !strings.EqualFold(strings.TrimSpace(sunoMode), "dev") && !callbackPublic, nil
	}

	enabled, err := strconv.ParseBool(raw)
	if err != nil {
		return false, fmt.Errorf("invalid SUNO_POLL_FALLBACK: %w", err)
	}
	return enabled, nil
}

func callbackQueueIfEnabled(queue ports.SunoCallbackQueue, enabled bool) ports.SunoCallbackQueue {
	if !enabled {
		return nil
	}
	return queue
}

func getenvDuration(key string, def time.Duration) time.Duration {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return def
	}
	parsed, err := time.ParseDuration(raw)
	if err != nil {
		log.Fatalf("worker: invalid %s duration: %v", key, err)
	}
	return parsed
}

func isInternalOnlyHost(host string) bool {
	host = strings.ToLower(strings.TrimSpace(host))
	switch host {
	case "localhost", "api", "nginx", "postgres", "redis", "minio":
		return true
	}

	if ip := net.ParseIP(host); ip != nil {
		return ip.IsLoopback() || ip.IsPrivate() || ip.IsUnspecified()
	}

	return !strings.Contains(host, ".")
}

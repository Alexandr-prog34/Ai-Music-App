package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"log/slog"
	"net"
	"net/http"
	"os"
	"time"

	_ "github.com/lib/pq"
	"github.com/redis/go-redis/v9"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/events"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/httpapi/handlers"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/queue"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/realtime"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/repo/postgres"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/service"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/storage"
)

func main() {
	port := getenv("API_PORT", "8080")
	postgresDSN := mustEnv("POSTGRES_DSN")
	redisAddr := getenv("REDIS_ADDR", "redis:6379")
	jobQueueKey := getenv("JOB_QUEUE_KEY", "jobs")
	callbackQueueKey := getenv("SUNO_CALLBACK_QUEUE_KEY", "suno_callbacks")
	callbackSecret := mustEnv("SUNO_CALLBACK_SECRET")
	notifierChannel := getenv("NOTIFIER_CHANNEL", events.DefaultChannel)

	logger := slog.Default()
	ctx := context.Background()

	rdb := redis.NewClient(&redis.Options{Addr: redisAddr})
	if err := rdb.Ping(ctx).Err(); err != nil {
		log.Fatalf("api: redis ping failed: %v", err)
	}

	db, err := postgres.Open(ctx, postgresDSN, postgres.DefaultPoolConfig())
	if err != nil {
		log.Fatalf("api: postgres open failed: %v", err)
	}
	defer db.Close()

	objectStorage, err := storage.NewMinIOObjectStorage(ctx, storage.Config{
		Endpoint:       mustEnv("S3_ENDPOINT"),
		PublicEndpoint: getenv("S3_PUBLIC_ENDPOINT", mustEnv("S3_ENDPOINT")),
		AccessKey:      mustEnv("S3_ACCESS_KEY"),
		SecretKey:      mustEnv("S3_SECRET_KEY"),
		Bucket:         mustEnv("S3_BUCKET"),
	})
	if err != nil {
		log.Fatalf("api: storage init failed: %v", err)
	}

	jobQueue := queue.NewRedisJobQueue(rdb, jobQueueKey, logger)
	sunoCallbackQueue := queue.NewRedisSunoCallbackQueue(rdb, callbackQueueKey, logger)
	jobRepo := postgres.NewJobRepo(db)
	userRepo := postgres.NewUserRepo(db)
	trackRepo := postgres.NewTrackRepo(db)

	jobWriteSvc := service.NewJobService(jobRepo, jobQueue, userRepo)
	jobReadSvc := service.NewJobReadService(jobRepo, userRepo, trackRepo, objectStorage)
	trackSvc := service.NewTrackService(userRepo, jobRepo, trackRepo, objectStorage)

	jobsHandler := handlers.NewJobsHandler(jobWriteSvc, logger)
	listJobsHandler := handlers.NewListJobsHandler(jobReadSvc, logger)
	getJobHandler := handlers.NewGetJobHandler(jobReadSvc, logger)
	listTracksHandler := handlers.NewListTracksHandler(trackSvc, logger)
	getTrackHandler := handlers.NewGetTrackHandler(trackSvc, logger)
	deleteTrackHandler := handlers.NewDeleteTrackHandler(trackSvc, logger)
	favoriteTrackHandler := handlers.NewFavoriteTrackHandler(trackSvc, true, logger)
	unfavoriteTrackHandler := handlers.NewFavoriteTrackHandler(trackSvc, false, logger)
	downloadTrackHandler := handlers.NewDownloadTrackHandler(trackSvc, logger)
	sunoCallbackHandler := handlers.NewSunoCallbackHandler(callbackSecret, sunoCallbackQueue, logger)

	hub := realtime.NewHub(logger)
	wsHandler := handlers.NewWSHandler(userRepo, hub, logger)
	subscriber := realtime.NewSubscriber(rdb, notifierChannel, hub, jobReadSvc, logger)
	go func() {
		if err := subscriber.Run(ctx); err != nil && err != context.Canceled {
			logger.Error("job update subscriber stopped", "err", err)
		}
	}()

	mux := http.NewServeMux()
	healthHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})
	readyHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()

		if err := checkPostgres(ctx, postgresDSN); err != nil {
			writeJSON(w, http.StatusServiceUnavailable, map[string]string{
				"status":  "unavailable",
				"message": "postgres: " + err.Error(),
			})
			return
		}
		if err := checkTCP(ctx, redisAddr); err != nil {
			writeJSON(w, http.StatusServiceUnavailable, map[string]string{
				"status":  "unavailable",
				"message": "redis: " + err.Error(),
			})
			return
		}

		writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
	})

	for _, prefix := range []string{"", "/api/v1"} {
		mux.Handle("GET "+route(prefix, "/health"), healthHandler)
		mux.Handle("GET "+route(prefix, "/ready"), readyHandler)
		mux.Handle("GET "+route(prefix, "/ws"), wsHandler)
		mux.Handle("POST "+route(prefix, "/jobs"), jobsHandler)
		mux.Handle("GET "+route(prefix, "/jobs"), listJobsHandler)
		mux.Handle("GET "+route(prefix, "/jobs/{id}"), getJobHandler)
		mux.Handle("GET "+route(prefix, "/tracks"), listTracksHandler)
		mux.Handle("GET "+route(prefix, "/tracks/{id}"), getTrackHandler)
		mux.Handle("DELETE "+route(prefix, "/tracks/{id}"), deleteTrackHandler)
		mux.Handle("PUT "+route(prefix, "/tracks/{id}/favorite"), favoriteTrackHandler)
		mux.Handle("DELETE "+route(prefix, "/tracks/{id}/favorite"), unfavoriteTrackHandler)
		mux.Handle("GET "+route(prefix, "/tracks/{id}/download"), downloadTrackHandler)
		mux.Handle("POST "+route(prefix, "/suno/callback"), sunoCallbackHandler)
		mux.Handle("POST "+route(prefix, "/internal/suno/callback"), sunoCallbackHandler)
	}

	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Accept, X-Device-Id, X-Suno-Callback-Secret")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		mux.ServeHTTP(w, r)
	})

	addr := ":" + port
	log.Printf("api listening on %s", addr)
	if err := http.ListenAndServe(addr, handler); err != nil {
		log.Fatal(err)
	}
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(payload); err != nil {
		slog.Default().Error("api: failed to encode json response", "err", err, "status", status)
	}
}

func route(prefix string, path string) string {
	if prefix == "" {
		return path
	}
	return prefix + path
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
		log.Fatalf("api: %s is empty", key)
	}
	return value
}

func checkPostgres(ctx context.Context, dsn string) error {
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return err
	}
	defer db.Close()
	return db.PingContext(ctx)
}

func checkTCP(ctx context.Context, addr string) error {
	var d net.Dialer
	conn, err := d.DialContext(ctx, "tcp", addr)
	if err != nil {
		return err
	}
	_ = conn.Close()
	return nil
}

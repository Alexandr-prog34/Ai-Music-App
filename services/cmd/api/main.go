package main

import (
	"context"
	"database/sql"
	"log"
	"log/slog"
	"net"
	"net/http"
	"os"
	"time"

	_ "github.com/lib/pq"
	"github.com/redis/go-redis/v9"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/httpapi/handlers"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/queue"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/repo/noop"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/repo/postgres"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/service"
)

func main() {
	port := getenv("API_PORT", "8080")
	postgresDSN := os.Getenv("POSTGRES_DSN")
	redisAddr := getenv("REDIS_ADDR", "redis:6379")

	// ---------- Logger ----------
	logger := slog.Default()

	// ---------- Redis ----------
	rdb := redis.NewClient(&redis.Options{
		Addr: redisAddr,
	})

	ctx := context.Background()
	if err := rdb.Ping(ctx).Err(); err != nil {
		log.Fatalf("api: redis ping failed: %v", err)
	}

	//  конструктор очереди требует logger
	jobQueue := queue.NewRedisJobQueue(rdb, "jobs", logger)

	var jobRepo ports.JobRepository = noop.NewJobRepo()
	var userRepo ports.UserRepository

	if postgresDSN == "" {
		logger.Warn("POSTGRES_DSN is empty, using noop job repository")
	} else {
		db, err := postgres.Open(ctx, postgresDSN, postgres.DefaultPoolConfig())
		if err != nil {
			logger.Warn("postgres unavailable, using noop job repository", "err", err)
		} else {
			defer db.Close()
			jobRepo = postgres.NewJobRepo(db)
			userRepo = postgres.NewUserRepo(db)
			logger.Info("postgres repositories enabled")
		}
	}

	// ---------- Сервис и handler для /jobs ----------
	jobSvc := service.NewJobService(jobRepo, jobQueue, userRepo)
	jobsHandler := handlers.NewJobsHandler(jobSvc, logger)

	//  handler для callback'ов Suno (локальная обработка suno.ErrInvalidCallback)
	sunoSecret := os.Getenv("SUNO_CALLBACK_SECRET")
	sunoCallbackHandler := handlers.NewSunoCallbackHandler(sunoSecret, logger)

	// ---------- HTTP mux ----------
	mux := http.NewServeMux()

	// /health
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})

	// /ready
	mux.HandleFunc("/ready", func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()

		if postgresDSN == "" {
			http.Error(w, "POSTGRES_DSN is empty", http.StatusServiceUnavailable)
			return
		}
		if err := checkPostgres(ctx, postgresDSN); err != nil {
			http.Error(w, "postgres: "+err.Error(), http.StatusServiceUnavailable)
			return
		}

		if redisAddr == "" {
			http.Error(w, "REDIS_ADDR is empty", http.StatusServiceUnavailable)
			return
		}
		if err := checkTCP(ctx, redisAddr); err != nil {
			http.Error(w, "redis: "+err.Error(), http.StatusServiceUnavailable)
			return
		}

		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ready"))
	})

	// /jobs
	mux.Handle("/jobs", jobsHandler)

	// /suno/callback
	mux.Handle("/suno/callback", sunoCallbackHandler)

	// ---------- CORS wrapper ----------
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Accept, X-Device-Id")

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

func getenv(key, def string) string {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	return v
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

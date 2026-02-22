package main

import (
	"context"
	"database/sql"
	"log"
	"net"
	"net/http"
	"os"
	"time"

	_ "github.com/lib/pq"
	"github.com/redis/go-redis/v9"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/httpapi/handlers"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/service"
	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/queue"
)

func main() {
	port := getenv("API_PORT", "8080")
	postgresDSN := os.Getenv("POSTGRES_DSN")
	redisAddr := getenv("REDIS_ADDR", "redis:6379")

	// ---------- Redis ----------
	rdb := redis.NewClient(&redis.Options{
		Addr: redisAddr,
	})

	ctx := context.Background()
	if err := rdb.Ping(ctx).Err(); err != nil {
		log.Fatalf("api: redis ping failed: %v", err)
	}

	jobQueue := queue.NewRedisJobQueue(rdb, "jobs")

	// ---------- Сервис и handler для /jobs ----------
	jobSvc := service.NewJobService(jobQueue)
	jobsHandler := handlers.NewJobsHandler(jobSvc)

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

	// /jobs — всё отдано в твой handler
	mux.Handle("/jobs", jobsHandler)

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
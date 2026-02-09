mkdir -p \
apps/mobile_flutter \
services/cmd/{api,worker} \
services/internal/{config,httpapi/handlers,worker} \
infra docs && \
touch \
README.md .gitignore .env.example \
apps/mobile_flutter/.gitkeep \
services/go.mod \
services/cmd/api/main.go \
services/cmd/worker/main.go \
services/internal/config/config.go \
services/internal/httpapi/server.go \
services/internal/httpapi/handlers/health.go \
services/internal/worker/consumer.go \
infra/docker-compose.yml \
docs/architecture.md

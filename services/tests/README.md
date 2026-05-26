## Tests

This directory contains project-level tests grouped by area.

Current layout:

- `domain/` for domain behavior tests
- `httpapi/` for HTTP handler and API contract tests
- `integration/` for future multi-component tests
- `e2e/` for future end-to-end scenarios

### What is here

There are two different ways to check the project:

1. Go tests
2. Smoke script

They are not the same thing.

### 1. Go tests

These tests verify Go code directly.

They do **not** require Docker if you only run the current tests in this folder.

Run from the repository root:

```bash
go test ./services/tests/...
```

Or from the Go module root:

```bash
cd services
go test ./tests/...
```

Run specific groups:

```bash
cd services
go test ./tests/domain
go test ./tests/httpapi
```

Verbose mode:

```bash
cd services
go test -v ./tests/...
```

### 2. Smoke script

File:

```bash
scripts/smoke_api.sh
```

This script does **not** run `go test`.

It sends real HTTP requests to the running application and checks that the main endpoints respond correctly.

It verifies:

- `GET /health`
- `GET /ready`
- `GET /jobs`
- validation errors for `POST /jobs`
- `POST /suno/callback`
- nginx health endpoint

### Docker is required for the smoke script

Before running the smoke script, you must start the project in Docker because the script expects a live API, nginx, postgres, redis, and other services.

Start from the repository root:

```bash
cp .env.example .env
docker compose -f infra/docker-compose.yml up --build
```

Then run the smoke script in another terminal:

```bash
bash scripts/smoke_api.sh
```

### Typical workflow

1. Start Docker services:

```bash
docker compose -f infra/docker-compose.yml up --build
```

2. Run Go tests:

```bash
cd services
go test ./tests/...
```

3. Run smoke checks against the live API:

```bash
bash scripts/smoke_api.sh
```

4. Stop Docker when finished:

```bash
docker compose -f infra/docker-compose.yml down
```

### Important

- If you want to check code behavior: run `go test`
- If you want to check the running application over HTTP: run `bash scripts/smoke_api.sh`
- If the smoke script fails because services are unavailable, first make sure Docker is running and containers are up

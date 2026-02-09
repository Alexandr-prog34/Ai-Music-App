# 📁 Итоговая структура проекта (целевая)

Ниже показана **целевая архитектура монорепозитория**.

Важно:
- ❌ не нужно создавать все папки сразу
- ✅ папки появляются по мере появления кода
- структура — это ориентир, а не чеклист

---

```
project-root/
├── README.md
├── .gitignore
├── .env.example
├── .editorconfig
│
├── apps/                         # клиентские приложения
│   └── mobile_flutter/           # Flutter mobile app
│       ├── lib/
│       │   ├── core/             # сеть, конфиг, DI, storage, utils
│       │   ├── features/         # фичи (auth, generate, library, player)
│       │   ├── shared/           # общие виджеты/тема
│       │   ├── app.dart
│       │   └── main.dart
│       ├── test/
│       └── pubspec.yaml
│
├── services/                     # весь Go backend (ОДИН go.mod)
│   ├── go.mod
│   ├── go.sum
│   │
│   ├── cmd/                      # точки входа (бинарники)
│   │   ├── api/                  # HTTP сервер
│   │   │   └── main.go
│   │   └── worker/               # фоновые задачи
│   │       └── main.go
│   │
│   ├── internal/                 # приватный код приложения
│   │   ├── config/               # env + конфиги
│   │   ├── logging/              # логирование
│   │   │
│   │   ├── httpapi/              # HTTP слой
│   │   │   ├── server.go
│   │   │   ├── router.go
│   │   │   ├── middleware/
│   │   │   └── handlers/
│   │   │
│   │   ├── domain/               # бизнес-логика (use-cases)
│   │   │   ├── auth/
│   │   │   ├── jobs/
│   │   │   └── tracks/
│   │   │
│   │   ├── repo/                 # доступ к данным (Postgres)
│   │   │   └── postgres/
│   │   │
│   │   ├── queue/                # Redis очередь
│   │   ├── storage/              # S3 / MinIO
│   │   ├── ai/                   # клиент внешнего AI API
│   │   └── worker/               # логика обработки job
│   │
│   └── migrations/               # SQL миграции БД
│
├── infra/                        # локальная инфраструктура
│   ├── docker-compose.yml
│   ├── docker/
│   │   ├── api.Dockerfile
│   │   └── worker.Dockerfile
│   └── scripts/
│
├── docs/                         # документация
│   ├── architecture.md
│   ├── api_contract.md
│   └── decisions/ (ADR)
│
└── .github/
    └── workflows/                # CI/CD
```

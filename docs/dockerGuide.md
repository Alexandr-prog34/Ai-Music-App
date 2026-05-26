# 🚀 Local Development Guide (Docker)

## 📦 Что нужно

Только:

* Docker Desktop (Mac / Linux / Windows)

Больше ничего устанавливать **не нужно**
(ни Postgres, ни Redis, ни MinIO, ни Go локально).

---

# ⚡ Быстрый старт

Из корня проекта:

```
cp .env.example .env 
docker compose -f infra/docker-compose.yml up --build
```

Готово ✅

После этого:

* API запущен
* Postgres запущен
* Redis запущен
* MinIO запущен
* bucket создаётся автоматически

---

# 🌐 Доступные сервисы

| Сервис   | Адрес                 | Назначение         |
| -------- | --------------------- | ------------------ |
| API      | http://localhost:8080 | backend сервер напрямую |
| Nginx    | http://localhost:8088 | reverse proxy до API |
| MinIO UI | http://localhost:9001 | файлы / S3 storage |
| Postgres | localhost:5432        | база данных        |
| Redis    | localhost:6379        | очередь / кэш      |
| Swagger  | http://localhost:8081 | визуальная проверка API |

По умолчанию `nginx` публикуется на `8088`, чтобы не конфликтовать с уже занятым `80` портом.
Если у вас `80` свободен и нужен именно он, задайте в `.env`:

```env
NGINX_HOST_PORT=80
```

---

# 🧪 Проверка что всё работает


## Swagger UI

Чтобы воспользоваться Swagger UI, просто зайдите на сайт:

```
http://localhost:8081
```

В этом интерфейсе можно визуально проверить и протестировать контракт API, посмотреть доступные эндпоинты, их параметры и ответы.

## API


```
curl http://localhost:8080/health

curl http://localhost:8080/ready
```

Ожидаем:

```
ok
ready
```

## Nginx

Проверка внешнего входа через reverse proxy:

```
curl http://localhost:8088/health

curl http://localhost:8088/ready
```

Ожидаем:

```
ok
ready
```

---

## Redis

```
docker exec -it infra-redis-1 redis-cli ping
```

Ожидаем:

```
PONG
```

---

## Postgres

```
docker exec -it infra-postgres-1 psql -U app -d app
```

Выход:

```
\q
```

---

## MinIO (S3)

Открыть в браузере:

```
http://localhost:9001
```

Логин:

```
minio
minio123
```

Bucket:

```
tracks
```

Создаётся автоматически.

---

# 🛠 Основные команды

## Запуск

```
docker compose -f infra/docker-compose.yml up
```

## Пересборка (если меняли код/Dockerfile/go.mod)

```
docker compose -f infra/docker-compose.yml up --build
```

## Остановка

```
docker compose -f infra/docker-compose.yml down
```

## Полный сброс (удалить БД и файлы)

```
docker compose -f infra/docker-compose.yml down -v
```

## Посмотреть контейнеры

```
docker compose ps
```

## Посмотреть логи

```
docker compose logs -f
```

---

# 🧠 Как это устроено (кратко)

## API

Go backend сервер
порт: 8080

Endpoints:

* `/health` — сервер жив
* `/ready` — готов к работе

---

## Postgres

Основная база данных
данные хранятся в Docker volume (`pgdata`)

---

## Redis

Очередь задач / кэш
используется worker’ом

---

## MinIO

Локальный S3-совместимый storage
используем для хранения файлов (mp3, треки)

В продакшене заменяется на AWS S3 / другое облако
код при этом не меняется.

---

# 👨‍💻 Типовой workflow разработчика

Поднять:

```
git pull
docker compose -f infra/docker-compose.yml up
```

КОДИМ

Остановить:

```
docker compose -f infra/docker-compose.yml down
```

---

# ❗ Важно

## Ничего локально ставить не нужно

Все сервисы уже внутри Docker.

## Если что-то сломалось

Самый простой способ:

```
docker compose -f infra/docker-compose.yml down -v
docker compose -f infra/docker-compose.yml up --build
```

Это полностью пересоздаст окружение.

---

# ✅ Готово

После запуска Docker можно сразу писать код backend или frontend — окружение полностью готово.

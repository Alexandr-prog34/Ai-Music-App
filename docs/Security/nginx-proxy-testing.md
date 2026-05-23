# Nginx Proxy Testing

Короткая памятка по тому, как сейчас проходят запросы в проекте и как это проверить руками.

## Как идёт запрос сейчас

На текущем этапе путь такой:

`client -> nginx -> api -> Redis queue -> worker`

Что делает каждый слой:

- `nginx` принимает внешний запрос на `localhost:8088`
- `nginx` проксирует `POST /jobs` во внутренний `api:8080`
- `api` валидирует запрос и обязательный заголовок `X-Device-Id`
- `api` создаёт `job` со статусом `queued`
- `api` кладёт `job_id` в Redis-очередь `jobs`
- `worker` сейчас не обрабатывает задачу, а только смотрит очередь и пишет её в лог

Важные файлы:

- `infra/docker-compose.yml`
- `nginx/nginx.conf`
- `nginx/conf.d/api.conf`
- `services/internal/httpapi/handlers/jobs.go`
- `services/internal/queue/redis_job_queue.go`
- `services/cmd/worker/main.go`

## Что уже можно проверить

Сейчас можно проверить:

- что `nginx` реально принимает запросы с хоста
- что `nginx` реально прокидывает их в `api`
- что `POST /jobs` создаёт `job`
- что `job_id` попадает в Redis-очередь
- что `nginx` режет слишком частые запросы по rate limit

Сейчас нельзя полноценно проверить:

- сохранение `job` в настоящую БД
- реальную обработку очереди воркером
- полный цикл генерации музыки через Suno

## Базовая проверка proxy

Прямой доступ к API:

```bash
curl -i http://localhost:8080/health
curl -i http://localhost:8080/ready
```

Доступ через `nginx`:

```bash
curl -i http://localhost:8088/health
curl -i http://localhost:8088/ready
```

Если ответ через `8088` приходит с `Server: nginx`, значит запрос действительно прошёл через reverse proxy.

## Создание job

```bash
curl -i -X POST http://localhost:8088/jobs \
  -H "Content-Type: application/json" \
  -H "X-Device-Id: 11111111-1111-1111-1111-111111111111" \
  -d '{"prompt":"A calm piano track with soft melodies","model":"V4_5ALL","instrumental":true}'
```

Ожидаем:

- `HTTP/1.1 201 Created`
- `status: "queued"`
- новый `id` в JSON-ответе

После этого проверьте:
    docker compose -f infra/docker-compose.yml exec -T redis redis-cli LLEN jobs

там станет на одну jod'у больше

## Проверка, что job попала в очередь

Подставить свой `job_id` из ответа:

```bash
JOB_ID=<job_id>

docker compose -f infra/docker-compose.yml exec -T redis redis-cli LLEN jobs
docker compose -f infra/docker-compose.yml exec -T redis redis-cli LRANGE jobs 0 -1
docker compose -f infra/docker-compose.yml exec -T redis redis-cli LPOS jobs "$JOB_ID"
docker compose -f infra/docker-compose.yml logs -f worker
```

Что означают проверки:

- `LLEN jobs` показывает длину очереди
- `LRANGE jobs 0 -1` показывает все `job_id`
- `LPOS jobs "$JOB_ID"` ищет именно нужную задачу
- лог `worker` показывает, что очередь реально видна приложению

## Проверка rate limit в nginx

Для `/jobs` сейчас настроен лимит по IP.

Сделать файл с телом запроса:

```bash
printf '%s' '{"prompt":"A calm piano track with soft melodies","model":"V4_5ALL","instrumental":true}' > /tmp/job.json
```

Быстро отправить пачку запросов:

```bash
for i in $(seq 1 10); do
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST http://localhost:8088/jobs \
    -H "Content-Type: application/json" \
    -H "X-Device-Id: 11111111-1111-1111-1111-111111111111" \
    --data-binary @/tmp/job.json)
  echo "$i $code"
done
```

Обычно часть запросов вернётся с `201`, а остальные с `429`.

Если до этого уже были тесты, лучше подождать около минуты и только потом повторять, иначе лимит ещё не успеет восстановиться.

## Как доказать, что 429 не дошёл до API

Снять длину очереди до и после burst-теста:

```bash
docker compose -f infra/docker-compose.yml exec -T redis redis-cli LLEN jobs
```

Потом посмотреть логи `nginx`:

```bash
docker compose -f infra/docker-compose.yml logs -f nginx
```

Если из 10 запросов успешно прошло только несколько, очередь вырастет только на число успешных `201`.
Это и будет означать, что запросы с `429` были остановлены на уровне `nginx` и не попали дальше в API.

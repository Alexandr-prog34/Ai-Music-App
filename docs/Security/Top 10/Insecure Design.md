
## 📌 4.1 Нет Rate Limiting

# A04 — Insecure Design
## 4.1 Отсутствие Rate Limiting

---
# Проблема

Если не ограничивать количество запросов:

- можно спамить создание job
- можно перегрузить Suno API
- можно положить сервер

Это архитектурная ошибка.

---

# ❌ Плохой подход

```go
r.Post("/jobs", h.CreateJob)
````

Без ограничений по:

- IP
- userID
- количеству запросов

---

# ✅ Решение — Rate Limiter Middleware

Пример простого лимитера на IP:

```go
var limiter = rate.NewLimiter(5, 10) // 5 req/sec, burst 10

func RateLimitMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        if !limiter.Allow() {
            http.Error(w, "too many requests", http.StatusTooManyRequests)
            return
        }
        next.ServeHTTP(w, r)
    })
}
```

---

# Лучше

- Лимитировать по userID
- Лимитировать создание job
- Ограничить WebSocket соединения

---

## 📌 4.2 Нет ограничения количества Job на пользователя

# A04 — Insecure Design
## 4.2 Нет ограничения количества Job

---

# Проблема

Если пользователь может создавать бесконечно много job:

- можно перегрузить базу
- можно создать финансовые потери (Suno платный)
- можно устроить DoS

---

# ❌ Плохо

```go
func (h *Handler) CreateJob(w http.ResponseWriter, r *http.Request) {
    h.repo.CreateJob(...)
}
````

Без проверки количества активных job.

---

# ✅ Правильно

Перед созданием:

```go
count, _ := h.repo.CountActiveJobs(ctx, userID)

if count >= 5 {
    http.Error(w, "too many active jobs", http.StatusForbidden)
    return
}
```

---

# Архитектурное правило

- Ограничить активные job (например 3–5)
- Ограничить общее число job в сутки

---

## 📌 4.3 Нет ограничения длины Prompt

# A04 — Insecure Design
## 4.3 Нет ограничения длины Prompt

---

# Проблема

Если не ограничить длину prompt:

- можно отправить 10MB текста
- можно перегрузить память
- можно увеличить стоимость генерации
- возможен DoS

---

# ❌ Плохо

```go
json.NewDecoder(r.Body).Decode(&req)
```

Без проверки длины строки.

---

# ✅ Правильно

Ограничить размер тела запроса:

```go
r.Body = http.MaxBytesReader(w, r.Body, 1<<20) // 1MB
```

И валидировать поле:

```go
if len(req.Prompt) == 0 || len(req.Prompt) > 500 {
    http.Error(w, "invalid prompt length", http.StatusBadRequest)
    return
}
```

---

# Архитектурное правило

- Ограничить размер JSON
- Ограничить длину строк
- Ограничить массивы

---

## 📌 4.4 Нет ограничения WebSocket соединений

# A04 — Insecure Design
## 4.4 Нет ограничения WebSocket соединений

---

# Проблема

Если не ограничить WebSocket:

- один пользователь может открыть 1000 соединений
- можно исчерпать file descriptors
- можно создать memory leak

---

# ❌ Плохо

```go
conn, _ := upgrader.Upgrade(w, r, nil)
````

Без контроля количества соединений.

---

# ✅ Правильно

Хранить счётчик активных соединений:

```go
if connectionCount[userID] >= 3 {
    http.Error(w, "too many connections", http.StatusForbidden)
    return
}
```

И уменьшать счётчик при закрытии.

---

# Архитектурное правило

- Ограничить соединения на пользователя
- Закрывать idle соединения
- Использовать ping/pong

---

## 📌 4.5 Отсутствие ограничения размера файлов

# A04 — Insecure Design
## 4.5 Нет ограничения размера файлов

---

# Проблема

Если принимаем файлы:

- можно загрузить огромный файл
- можно заполнить диск
- можно вызвать OOM

---

# ❌ Плохо

```go
file, _, _ := r.FormFile("file")
````

Без ограничения размера.

---

# ✅ Правильно

```go
r.Body = http.MaxBytesReader(w, r.Body, 10<<20) // 10MB
```

И проверять Content-Type.

---

# Архитектурное правило

- Ограничить размер загрузки
- Проверять тип файла 
- Хранить вне публичной директории

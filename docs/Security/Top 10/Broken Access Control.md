# A01 — Broken Access Control
## AI Music Generator (Go Backend)

---

# 1. Что это

Broken Access Control — это ситуация, когда пользователь получает доступ к данным или действиям, которые ему не принадлежат.

В нашем проекте это самая опасная категория, потому что:

- есть пользовательские job'ы
- есть приватные треки
- есть WebSocket подписки
- есть асинхронные callback'и

Ошибка в проверке `userID` = утечка данных.

---

# 2. Где мы можем столкнуться с этим

## 2.1 Получение чужого job

GET /jobs/{id}

Если мы просто ищем job по ID — это уже уязвимость.

## 2.2 Скачивание чужого трека

GET /tracks/{id}/download

Без проверки владельца можно скачать любой файл.

## 2.3 WebSocket подписка

/ws?job_id=...

Если не проверить, что job принадлежит пользователю — он сможет слушать чужие события.

## 2.4 Callback обработка

Если при обработке callback мы не проверяем связь job ↔ user — возможна подмена.

---

# 3. Пример плохого кода

## ❌ Уязвимый handler

```go
func (h *Handler) GetJob(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")

    job, err := h.repo.GetByID(r.Context(), id)
    if err != nil {
        http.Error(w, "not found", http.StatusNotFound)
        return
    }

    json.NewEncoder(w).Encode(job)
}
```


# 4. Правильная реализация 
## Шаг 1 — достать userID из контекста

Предполагаем, что middleware уже проверил JWT и положил userID в context.
## Шаг 2 — проверка ownership

```go
func (h *Handler) GetJob(w http.ResponseWriter, r *http.Request) {  
    ctx := r.Context()  
  
    userID := ctx.Value("userID").(string)  
    jobID := chi.URLParam(r, "id")  
  
    job, err := h.repo.GetByID(ctx, jobID)  
    if err != nil {  
        http.Error(w, "not found", http.StatusNotFound)  
        return  
    }  
  
    if job.UserID != userID {  
        http.Error(w, "forbidden", http.StatusForbidden)  
        return  
    }  
  
    json.NewEncoder(w).Encode(job)  
}
```

> Теперь пользователь может получить только свои job'ы.

# 5. Лучший подход — проверка на уровне репозитория

Чтобы разработчики не забывали проверку, лучше встроить её в запрос.

## Репозиторий

``` go 
func (r *Repository) GetByIDAndUser(  
    ctx context.Context,  
    jobID string,  
    userID string,  
) (*Job, error) {  
  
    query := `  
        SELECT id, user_id, status  
        FROM jobs  
        WHERE id = $1 AND user_id = $2  
    `  
  
    var job Job  
    err := r.db.QueryRowContext(ctx, query, jobID, userID).  
        Scan(&job.ID, &job.UserID, &job.Status)  
  
    if err != nil {  
        return nil, err  
    }  
  
    return &job, nil  
}
```

## Handler

```go
func (h *Handler) GetJob(w http.ResponseWriter, r *http.Request) {  
    ctx := r.Context()  
  
    userID := ctx.Value("userID").(string)  
    jobID := chi.URLParam(r, "id")  
  
    job, err := h.repo.GetByIDAndUser(ctx, jobID, userID)  
    if err != nil {  
        http.Error(w, "not found", http.StatusNotFound)  
        return  
    }  
  
    json.NewEncoder(w).Encode(job)  
}
```

> Теперь невозможно забыть проверку владельца.
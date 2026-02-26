# A03 — Injection
## AI Music Generator (Go Backend)

---

# 1. Что это

Injection — это внедрение вредоносных данных в запросы, команды или логи, из-за чего система выполняет непредусмотренные действия.

В нашем проекте наиболее актуальны:

- SQL Injection
- Redis Injection
- Command Injection
- Log Injection
- JSON / Input Injection

---

# 2. SQL Injection

## Где риск

- Поиск job по ID
- Фильтрация
- Админские панели
- Любые динамические WHERE

---

## ❌ Уязвимый код

```go
func (r *Repository) GetJob(ctx context.Context, id string) (*Job, error) {
    query := "SELECT id, user_id, status FROM jobs WHERE id = '" + id + "'"

    row := r.db.QueryRowContext(ctx, query)

    var job Job
    err := row.Scan(&job.ID, &job.UserID, &job.Status)
    if err != nil {
        return nil, err
    }

    return &job, nil
}
```

Если передать:
``` sql
' OR 1=1 --
```

Запрос станет:
``` sql
SELECT ... WHERE id = '' OR 1=1 --'
```

Будут возвращены чужие данные.

## ✅ Правильный код (Prepared Statements)


``` go
func (r *Repository) GetJob(ctx context.Context, id string) (*Job, error) {  
    query := `  
        SELECT id, user_id, status  
        FROM jobs  
        WHERE id = $1  
    `  
  
    var job Job  
    err := r.db.QueryRowContext(ctx, query, id).  
        Scan(&job.ID, &job.UserID, &job.Status)  
  
    if err != nil {  
        return nil, err  
    }  
  
    return &job, nil  
}
```

Правило:  
Никогда не конкатенировать пользовательский ввод в SQL.

---
# 3. Redis Injection

## Где риск

- Формирование ключей
- Использование пользовательского ввода в командах

Плохая практика:
``` go 
key := "job:" + userInput
rdb.Get(ctx, key)
```

Если userInput содержит спецсимволы или неожиданные данные — можно ломать структуру ключей.

## ✅ Правильно

- Валидировать ID
- Использовать UUID
- Проверять формат


``` go
if _, err := uuid.Parse(userInput); err != nil {  
    return errors.New("invalid id")  
}  
  
key := fmt.Sprintf("job:%s", userInput)
```

---

# 6. JSON / Input Injection

## Где риск

- CreateJobRequest
- Prompt генерации
- Фильтры
- Query параметры

## ❌ Плохо

Не валидировать входные данные:
``` go
var req CreateJobRequest
json.NewDecoder(r.Body).Decode(&req)
```

Без проверки:
- длины строки
- обязательных полей
- формата

---

## ✅ Правильно

```go
if len(req.Prompt) == 0 || len(req.Prompt) > 500 {  
    return errors.New("invalid prompt length")  
}
```

Рекомендуется:

- использовать валидаторы
- ограничивать размер тела запроса

---

# 7. Валидация ID
Никогда не доверять ID из URL.

## ❌ Плохо

```go
id := chi.URLParam(r, "id")
```
Без проверки формата.

---

## ✅ Правильно

i
``` go
id := chi.URLParam(r, "id")  
  
if _, err := uuid.Parse(id); err != nil {  
    http.Error(w, "invalid id", http.StatusBadRequest)  
    return  
}
```

---

# 8. Основные правила защиты

- Никогда не конкатенировать SQL
- Использовать prepared statements
- Валидировать UUID
- Ограничивать длину строк
- Проверять типы данных
- Не выполнять shell-команды из пользовательского ввода
- Экранировать данные в логах
- Ограничивать размер JSON body
# A07 — Identification and Authentication Failures
## AI Music Generator (Go Backend)

---

# 1. Что это

Authentication Failures — ошибки в механизме аутентификации.

Если Broken Access Control — это про доступ к ресурсам,  
то Authentication — это про подтверждение личности пользователя.

В проекте используется JWT, поэтому основные риски:

- неправильная проверка подписи
- отсутствие проверки алгоритма
- отсутствие expiration
- отсутствие refresh token механизма
- отсутствие logout-инвалидации
- использование слабого секрета

Это критическая категория.

---

# 2. Где возможны проблемы

- JWT middleware
- Генерация access token
- Обновление токена
- Logout
- WebSocket авторизация
- Использование токена после истечения срока

---

# 3. Уязвимые примеры

## 3.1 Отсутствие проверки подписи

❌ Плохой код:

```go
token, _ := jwt.Parse(tokenString, nil)
claims := token.Claims.(jwt.MapClaims)
userID := claims["user_id"].(string)
```

Проблема:
- подпись не проверяется
- можно подделать токен
---
## 3.2 Отсутствие проверки алгоритма

❌ Плохой код:
``` go
jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {  
    return []byte(secret), nil  
})
```

Проблема:
- не проверяется token.Method 
- возможна подмена алгоритма
---
## 3.3 JWT без expiration

❌ Плохая генерация:

``` go
claims := jwt.MapClaims{  
    "user_id": user.ID,  
}
```

Проблема:
- токен действует бесконечно
- украденный токен = постоянный доступ
---

# 4 Безопасная реализация JWT middleware

``` go
func JWTMiddleware(secret string) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

            authHeader := r.Header.Get("Authorization")
            if authHeader == "" {
                http.Error(w, "unauthorized", http.StatusUnauthorized)
                return
            }

            tokenString := strings.TrimPrefix(authHeader, "Bearer ")

            token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {

                if token.Method != jwt.SigningMethodHS256 {
                    return nil, fmt.Errorf("unexpected signing method")
                }

                return []byte(secret), nil
            })

            if err != nil || !token.Valid {
                http.Error(w, "unauthorized", http.StatusUnauthorized)
                return
            }

            claims, ok := token.Claims.(jwt.MapClaims)
            if !ok {
                http.Error(w, "unauthorized", http.StatusUnauthorized)
                return
            }

            exp, ok := claims["exp"].(float64)
            if !ok || time.Now().Unix() > int64(exp) {
                http.Error(w, "token expired", http.StatusUnauthorized)
                return
            }

            userID, ok := claims["user_id"].(string)
            if !ok {
                http.Error(w, "invalid token", http.StatusUnauthorized)
                return
            }

            ctx := context.WithValue(r.Context(), "userID", userID)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```

---

# 5 Правильная генерация токена 

``` go 
func GenerateAccessToken(userID string, secret string) (string, error) {
    claims := jwt.MapClaims{
        "user_id": userID,
        "exp":     time.Now().Add(15 * time.Minute).Unix(),
        "iat":     time.Now().Unix(),
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(secret))
}
```

> Access token должен жить недолго (10–15 минут).

---

# 6. Refresh Token стратегия

Правильная схема:

- Access token — короткий срок жизни
- Refresh token — хранится в базе
- При logout refresh удаляется
- При обновлении проверяется существование refresh в БД

Без refresh токена:

- либо access живёт долго (опасно)
- либо пользователь постоянно логинится
---

# 7. Logout проблема

JWT stateless.  
Если ничего не хранить — logout не работает.

Решения:
1. Хранить refresh токены в БД
2. При logout удалять refresh
3. Проверять refresh при обновлении
4. Опционально — blacklist access токенов
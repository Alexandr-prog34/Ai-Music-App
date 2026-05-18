# Git Workflow

## Ветки

### main
Стабильная версия.  
То, что можно показать или задеплоить.  
Напрямую не пушим.

### dev
Общая рабочая ветка.  
Сюда сливаются все фичи.  
Напрямую не пушим.

### feature/*
Отдельная ветка под каждую задачу.  
Создается от dev.  
Примеры:
- feature/front-login
- feature/back-auth
- feature/DevOps-git

---

## Как работать

### 0. Правила 
- Одна задача = одна ветка `feature/...`
- В `dev` и `main` напрямую не пушим
- Всегда льём изменения через PR: `feature -> dev`, потом `dev -> main`

---

## 1. Начать задачу (создать ветку)
Обнови `dev` и создай feature-ветку:
```
git checkout dev
git pull origin dev
git checkout -b feature/my-task
```

---

## 2. Делать коммиты
```
git add .
git commit -m "short message"
```

---

## 3. Push свою ветку

Запушить ветку на сервер:

```
git push -u origin feature/my-task
```

---

## 4. Что делать, если в dev появились новые изменения (кто-то влил фичи)

Если ты начал утром, а днём кто-то влил новое в `dev`, тебе нужно подтянуть `dev` в свою ветку:

1. Сохрани изменения (закоммить)

```
git status
git add .
git commit -m "short message"
```

2. Обнови `dev`

```
git checkout dev
git pull origin dev
```

3. Влей `dev` в свою feature-ветку

```
git checkout feature/my-task
git merge dev
```

4. Если конфликты:

* исправь файлы
* затем:

```
git add .
git commit -m "merge dev"
```

5. Запушь обновлённую ветку:

```
git push
```

---

## 5. Pull Request (PR): как вливать свою фичу в dev

### 5.1 Создать PR

Когда фича готова:

* создаёшь PR **из `feature/my-task` в `dev`**
* в описании укажи:

  * что сделал
  * как проверить (1–3 шага)
  * (для фронта) скрин/видео в тг

### 5.2 Если после открытия PR в dev снова появились изменения

Повтори шаг из раздела 4:

```
git checkout dev
git pull origin dev
git checkout feature/my-task
git merge dev
git push
```

### 5.3 Мерж PR

После того как кто-то посмотрел (хотя бы 1 человек):

* мержим PR в `dev`
* удаляем ветку `feature/my-task`

---

## 6. Обновить main из dev (когда всё стабильно)

Когда в `dev` накопилось и “в целом работает”, обновляем `main`:

```
git checkout main
git pull origin main
git merge dev
git push origin main
```

---



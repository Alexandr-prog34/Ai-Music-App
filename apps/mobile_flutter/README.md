# Flutter Backend Integration

## Что реализовано

### REST API

Файлы:

```text
lib/core/network/
```

---

## Jobs API

Файл:

```text
jobs_api.dart
```

Реализованы:

* `POST /jobs`
* `GET /jobs`
* `GET /jobs/{id}`

---

## Tracks API

Файл:

```text
tracks_api.dart
```

Реализованы:

* `GET /tracks`
* `GET /tracks/{id}`
* `DELETE /tracks/{id}`
* `PUT /tracks/{id}/favorite`
* `DELETE /tracks/{id}/favorite`
* `GET /tracks/{id}/download`

---

## WebSocket

Файл:

```text
websocket_api.dart
```

Реализовано:

* websocket connect
* realtime stream listening
* JSON parsing
* reconnect
* ping/pong
* disconnect

---

# Архитектура

```text
UI → UseCase → Repository → API → Backend
```

UI не должен использовать API напрямую.

Используем только usecases.

---

# Где usecases

## Generation

```text
features/generation/domain/usecases/
```

Есть:

* `CreateJobUseCase`
* `GetJobUseCase`
* `ListJobsUseCase`
* `ListenJobsUseCase`

### Что делает каждый:

#### CreateJobUseCase

Создаёт генерацию.

Использовать на кнопке Generate.

Пример:

```dart
await createJobUseCase(
  CreateJobRequest(
    prompt: promptController.text,
  ),
);
```

---

#### GetJobUseCase

Получить одну job по id.

Использовать:

* polling
* refresh status

Пример:

```dart
final job = await getJobUseCase(jobId);
```

---

#### ListJobsUseCase

Получить список jobs.

Использовать:

* history screen
* generation history

Пример:

```dart
final jobs = await listJobsUseCase();
```

---

#### ListenJobsUseCase

Realtime websocket updates.

Использовать:

* queued → processing → ready
* realtime status updates

Пример:

```dart
listenJobsUseCase().listen((job) {

  print(job.status);

});
```

---

## Tracks

```text
features/library/domain/usecases/
```

Есть:

* `GetTracksUseCase`
* `DeleteTrackUseCase`
* `AddFavoriteUseCase`
* `RemoveFavoriteUseCase`

### Что делает каждый:

#### GetTracksUseCase

Получить список треков.

Использовать:

* library screen

Пример:

```dart
final tracks = await getTracksUseCase();
```

---

#### DeleteTrackUseCase

Удалить трек.

Пример:

```dart
await deleteTrackUseCase(trackId);
```

---

#### AddFavoriteUseCase

Добавить трек в избранное.

Пример:

```dart
await addFavoriteUseCase(trackId);
```

---

#### RemoveFavoriteUseCase

Убрать трек из избранного.

Пример:

```dart
await removeFavoriteUseCase(trackId);
```

---

# Shared domain models

```text
lib/shared/domain/
```

Там находятся:

* `Job`
* `Track`
* `CreateJobRequest`
* websocket models
* enums

---


# Важно

UI не должен:

* делать `dio.get/post`
* использовать `JobsApi`
* использовать `TracksApi`

Только usecases.

# Frontend/Backend Integration Log

Дата: 2026-05-26

## Цель

Довести частично работающую интеграцию Flutter frontend и Go backend после того, как уже заработали:

- `POST /jobs`
- websocket updates
- loading flow
- generation queue
- async generation flow
- worker + redis + realtime
- создание jobs на backend

## Что проверили перед изменениями

Проверены существующие backend routes в `services/cmd/api/main.go` и handlers/services:

- `GET /health`
- `GET /ready`
- `GET /ws`
- `POST /jobs`
- `GET /jobs`
- `GET /jobs/{id}`
- `GET /tracks`
- `GET /tracks/{id}`
- `DELETE /tracks/{id}`
- `PUT /tracks/{id}/favorite`
- `DELETE /tracks/{id}/favorite`
- `GET /tracks/{id}/download`
- `POST /suno/callback`
- `POST /internal/suno/callback`

На момент проверки backend endpoints для playlists, rename track и upload cover image не были найдены.

## Уточнение: что возвращается после генерации

Саша прав, но формулировка требует уточнения.

После успешной генерации Suno callback `complete` может принести для каждого результата:

- audio link:
  - `audio_url`
  - или fallback `source_audio_url`
- image link:
  - `image_url`
  - или fallback `source_image_url`

В backend это обрабатывается в `services/internal/service/suno_callback_service.go`:

- audio URL обязателен;
- image URL optional, но если он есть, backend тоже скачивает его;
- audio и image не отдаются клиенту напрямую как постоянные Suno links;
- backend скачивает их в object storage/MinIO;
- затем frontend получает presigned links через hydrated track fields.

То есть для готового track frontend получает:

- `audio_url`
- `stream_url`
- `image_url`, если у трека есть обложка

Это описано в `services/internal/view/job.go` в `view.Track`.

Важно:

- `POST /jobs` сразу не возвращает готовые ссылки на mp3/image.
- Ссылки появляются позже, когда job становится `ready`.
- Они приходят через websocket update или через `GET /jobs/{id}` / `GET /tracks`.
- Обычно Suno может вернуть несколько результатов на одну генерацию, поэтому `job.tracks` может содержать больше одного track. У каждого track свои `audio_url` и optional `image_url`.

## Проблема 1: download track использовал fake int id

Симптом:

- Frontend вызывал `GET /tracks/2/download`
- Backend ожидает UUID track id
- Backend возвращал `invalid track id`

Причина:

- Player и Library работали через `InMemorySongRepository`.
- Этот repository сидил fake songs с id `'1'` и `'2'`.
- Player вызывал download через `current.song.id`, поэтому в URL попадал integer-like id, а не UUID из backend.

Что изменено:

- `InMemorySongRepository` заменен на `BackendSongRepository`.
- Library теперь получает songs из `GET /tracks`.
- `Song.id` теперь равен backend `Track.id`, то есть реальному UUID.
- Rename/delete/favorite в `SongRepository` теперь прокинуты на backend tracks API.

Файлы:

- `apps/mobile_flutter/lib/features/library/data/song_repository_impl.dart`
- `apps/mobile_flutter/lib/core/network/tracks_api.dart`

## Проблема 2: custom_mode mapping

Симптом:

- Backend валидировал ошибку: `title must be empty when custom_mode=false`.

Причина:

- Frontend мог отправлять `title` при `custom_mode=false`.
- Backend контракт строгий:
  - `custom_mode=false`: разрешен только обычный `prompt`, остальные custom fields должны быть пустыми.
  - `custom_mode=true`: используются lyrics/title/style/advanced options.

Что изменено:

- Для обычного description prompt без advanced options отправляется:
  - `custom_mode=false`
  - `title=null`
  - `style=null`
  - `vocal_gender=null`
- Для lyrics/title/vocal/instrumental отправляется:
  - `custom_mode=true`
  - `title`
  - `style`
  - optional `vocal_gender`

Файл:

- `apps/mobile_flutter/lib/features/generation/presentation/generation_controller.dart`

## Проблема 3: completed generation не открывал player

Причина:

- Backend возвращает финальный статус `ready`.
- Frontend проверял `job.status.name == 'completed'`.

Что изменено:

- Frontend теперь ждет статус `ready`.
- WebSocket updates фильтруются по `createdJob.id`, чтобы чужой job update не открыл player.
- Когда job становится `ready`, frontend берет первый `track.id` из `job.tracks` и открывает `PlayerScreen`.
- Loader закрывается перед открытием player.

Файлы:

- `apps/mobile_flutter/lib/features/generation/presentation/generation_controller.dart`
- `apps/mobile_flutter/lib/features/generation/presentation/generation_screen.dart`

## Failed generation UI

Что изменено:

- При статусе `failed` frontend:
  - закрывает loading state
  - показывает backend `job.error`, если он пришел
  - иначе показывает `Generation failed`

Файлы:

- `apps/mobile_flutter/lib/features/generation/presentation/generation_controller.dart`
- `apps/mobile_flutter/lib/features/generation/presentation/generation_screen.dart`

## Rename track

Backend endpoints для rename не существовали.

Был временно добавлен backend endpoint `PATCH /tracks/{id}`, но затем это было откатано как backend feature creep.

Текущее состояние после selective revert:

- backend route `PATCH /tracks/{id}` удален;
- backend handler `RenameTrackHandler` удален;
- backend service method `RenameTrack` удален;
- backend repository method `RenameTrack` удален;
- SQL `qTrackRename` удален.

Интеграционные fixes для generation/download не трогались.

## Upload cover image

Backend endpoints для cover upload не существовали.

Был временно добавлен backend endpoint `PUT /tracks/{id}/cover`, но затем это было откатано как backend feature creep.

Текущее состояние после selective revert:

- backend route `PUT /tracks/{id}/cover` удален;
- backend handler `UploadTrackCoverHandler` удален;
- backend service method `UploadCover` удален;
- backend generic object storage method `Upload` удален;
- backend repository method `UpdateCover` удален;
- SQL `qTrackUpdateCover` удален.

Интеграционные fixes для generation/download не трогались.

## Playlists

Что найдено:

- Во Flutter уже есть локальная playlist feature:
  - `apps/mobile_flutter/lib/core/models/playlist.dart`
  - `apps/mobile_flutter/lib/core/repositories/playlist_repository.dart`
  - `apps/mobile_flutter/lib/features/library/data/playlist_repository_impl.dart`
- Backend endpoints для playlists не найдены.

Текущее состояние:

- Playlists пока остаются локальными in-memory на frontend.
- Backend playlists требуют отдельной схемы БД, migrations, repo/service/handlers и routes.
- Это лучше делать отдельным шагом, чтобы не смешивать с hotfix интеграции jobs/tracks.

## Что не удалось проверить

- `go test ./...` не запущен: в окружении не найден `go`.
- `gofmt` не запущен: в окружении не найден `gofmt`.
- `flutter analyze` не запущен: Flutter пытался писать в `/home/ooicnw/flutter/bin/cache/engine.stamp`, но filesystem для этого read-only.
- `dart format` не запущен по той же причине; escalated запуск был отклонен пользователем.

## Следующие шаги

1. Запустить `gofmt` и `go test ./...` там, где доступен Go toolchain.
2. Запустить `dart format` и `flutter analyze` с доступом к Flutter cache.
3. Реализовать rename track отдельным вертикальным срезом, если backend API для этого нужен.
4. Реализовать upload cover image отдельным вертикальным срезом, если backend API для этого нужен.
5. Реализовать backend playlists отдельным вертикальным срезом:
   - migrations
   - domain/repo/service
   - handlers
   - routes
   - frontend API repository вместо in-memory playlist repository

## UI glue inventory перед подключением кнопок

Дата: 2026-05-26

Ограничения для этого шага:

- backend не менять;
- backend routes/handlers/services/repositories не менять;
- database/migrations не менять;
- websocket/generation architecture не менять;
- новые endpoints не создавать;
- новые экраны/repositories/redesign не делать;
- можно только соединять существующие frontend кнопки с уже существующей логикой.

### Уже существующие backend endpoints, которыми можно пользоваться

- `POST /jobs`
- `GET /jobs`
- `GET /jobs/{id}`
- `GET /tracks`
- `GET /tracks/{id}`
- `DELETE /tracks/{id}`
- `PUT /tracks/{id}/favorite`
- `DELETE /tracks/{id}/favorite`
- `GET /tracks/{id}/download`
- websocket `/ws`

### Уже существующие frontend methods/API

Tracks:

- `TracksApi.listTracks`
- `TracksApi.getTrack`
- `TracksApi.deleteTrack`
- `TracksApi.addFavorite`
- `TracksApi.removeFavorite`
- `TracksApi.getDownloadUrl`

Jobs:

- `JobsApi.createJob`
- `JobsApi.listJobs`
- `JobsApi.getJob`
- `WebSocketApi.connect/listen`

Local playlists:

- `PlaylistRepository.getAll`
- `PlaylistRepository.getById`
- `PlaylistRepository.create`
- `PlaylistRepository.update`
- `PlaylistRepository.delete`
- `PlaylistRepository.addSong`
- `PlaylistRepository.removeSong`

Player/local state:

- `PlayerController.togglePlay`
- `PlayerController.seek`
- `PlayerController.toggleLike`
- `PlayerController.getDownloadUrl`

### Buttons/actions already connected

- Create generation button -> `GenerationFormController.submit`.
- Generation mode tabs -> `setMode`.
- Mood/genre pills and sheets -> `selectMood` / `selectGenre`.
- Advanced options toggle -> `toggleAdvanced`.
- Vocal gender tiles -> `setVocalGender`.
- Library song tile -> opens existing `PlayerScreen`.
- Library retry -> invalidates `songsProvider`.
- Library New Playlist -> local `playlistsProvider.create`.
- Library Favorites -> opens favorites sheet from liked IDs.
- Player back -> `Navigator.pop`.
- Player more menu -> opens existing options dialog.
- Player download -> `PlayerController.getDownloadUrl` -> `TracksApi.getDownloadUrl`.
- Player like -> `PlayerController.toggleLike` -> backend favorite endpoints.
- Player play/pause -> local `togglePlay`.
- Player progress slider -> local `seek`.
- Player Add to Playlist -> local playlist repository `create/addSong`.
- Player Delete Song -> backend `DELETE /tracks/{id}` through `songRepositoryProvider.delete`.

### Disconnected or broken integration points

1. Player previous/next buttons

- Location: `apps/mobile_flutter/lib/features/player/presentation/player_screen.dart`
- Current code: `onTap: () {}`
- Existing method/API: none found for queue navigation.
- Backend endpoint: none needed unless queue state becomes backend-driven.
- Action for now: do not implement without changing player state model/navigation behavior.

2. Player Edit Song Picture dialog

- Location: `apps/mobile_flutter/lib/features/player/presentation/player_screen.dart`
- Current behavior: shows snackbar `"$action is not connected yet"`.
- Buttons:
  - `Take Picture`
  - `Choose from Library`
  - `Remove Picture`
- Existing frontend method: `TracksApi.uploadCover` exists, but it points to `PUT /tracks/{id}/cover`.
- Backend endpoint: absent after selective revert.
- Also missing dependency/integration for picking/taking an image, such as `image_picker` or `file_picker`.
- Action for now: report missing backend/API and image picker integration; do not create backend endpoint.

3. Library New Playlist picture dialog

- Location: `apps/mobile_flutter/lib/features/library/presentation/library_screen.dart`
- Current behavior: dialog opens and returns action string, but caller ignores result.
- Buttons:
  - `Take Picture`
  - `Choose from Library`
  - `Remove Picture`
- Existing local model supports `Playlist.coverPath`.
- Existing create flow only returns playlist name; no selected cover path is passed into `PlaylistRepository.create`.
- No image picker dependency/integration exists.
- Backend playlist API absent.
- Action for now: do not redesign dialog result or add picker without explicit approval.

4. Rename Song Title

- Location: `apps/mobile_flutter/lib/features/player/presentation/player_screen.dart`
- Current UI is connected to `PlayerController.renameSong`.
- Current repository path calls `SongRepository.save`.
- Current `BackendSongRepository.save` calls `TracksApi.renameTrack`.
- `TracksApi.renameTrack` points to `PATCH /tracks/{id}`.
- Backend endpoint `PATCH /tracks/{id}` is absent after selective revert.
- Action for now: report as missing backend integration point; do not recreate backend endpoint.

5. Frontend-only stale methods after backend revert

- `TracksApi.renameTrack` exists but backend route is absent.
- `TracksApi.uploadCover` exists but backend route is absent.
- These methods should not be wired further until backend API is intentionally added.

## Failed generation loading fix

Дата: 2026-05-27

Проблема:

- Backend корректно помечает job как `failed`.
- Worker логирует `worker job marked failed`.
- Frontend loading dialog мог оставаться открытым бесконечно.

Причины на frontend:

1. `GenerationRepositoryImpl.listenJobs` фильтровал websocket messages так:

   - `message.type == "job_updated"`

   Но `message.type` является enum `WsType`, а не строкой. Из-за этого `job_updated` events могли не доходить до `GenerationFormController`.

2. Loading dialog открывается через `showDialog`, который по умолчанию использует root navigator.
   Listener закрывал dialog через обычный `Navigator.of(context).pop()`, что может не закрыть root dialog в shell/navigation setup.

Минимальное исправление:

- Сравнение websocket type заменено на `WsType.jobUpdated`.
- При error/failed и completed flow dialog закрывается через `Navigator.of(context, rootNavigator: true)`.
- Backend, websocket architecture и generation architecture не менялись.

Файлы:

- `apps/mobile_flutter/lib/features/generation/data/repositories/generation_repository_impl.dart`
- `apps/mobile_flutter/lib/features/generation/presentation/generation_screen.dart`

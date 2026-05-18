CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================
-- users
-- =========================
CREATE TABLE users (
                       id         UUID PRIMARY KEY,
                       install_id UUID UNIQUE NOT NULL,
                       created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================
-- jobs
-- =========================
CREATE TYPE job_status AS ENUM ('queued', 'processing', 'ready', 'failed');

CREATE TABLE jobs (
                      id            UUID PRIMARY KEY,
                      user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

                      status        job_status NOT NULL,

                      prompt        TEXT NOT NULL,
                      custom_mode   BOOLEAN NOT NULL DEFAULT false,
                      style         TEXT NULL,
                      title         TEXT NULL,
                      instrumental  BOOLEAN NOT NULL DEFAULT false,
                      model         TEXT NOT NULL,
                      vocal_gender  TEXT NULL,
                      negative_tags TEXT NULL,

                      suno_task_id  TEXT NULL, -- внутреннее

                      error         TEXT NULL,

                      attempts      INT NOT NULL DEFAULT 0 CHECK (attempts >= 0),
                      started_at    TIMESTAMPTZ NULL,
                      finished_at   TIMESTAMPTZ NULL,

                      created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
                      updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Индексы под API
CREATE INDEX jobs_user_id_idx ON jobs(user_id);
CREATE INDEX jobs_status_idx ON jobs(status);
CREATE INDEX jobs_created_at_idx ON jobs(created_at);

-- Быстрый список job пользователя (последние сверху)
CREATE INDEX jobs_user_created_desc_idx ON jobs(user_id, created_at DESC);

-- Callback: поиск job по taskId + защита от дублей taskId
CREATE UNIQUE INDEX jobs_suno_task_id_uq
    ON jobs(suno_task_id)
    WHERE suno_task_id IS NOT NULL;

-- Авто-обновление updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER jobs_set_updated_at
    BEFORE UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();


-- =========================
-- tracks
-- =========================
CREATE TABLE tracks (
                        id            UUID PRIMARY KEY,
                        job_id        UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,

                        suno_audio_id TEXT NOT NULL,
                        title         TEXT NOT NULL,
                        tags          TEXT NULL,

                        duration_sec  DOUBLE PRECISION NOT NULL CHECK (duration_sec > 0),

    -- ✅ MinIO координаты (истина хранения)
                        audio_bucket  TEXT NOT NULL DEFAULT 'audio',
                        audio_key     TEXT NULL,

                        image_bucket  TEXT NOT NULL DEFAULT 'images',
                        image_key     TEXT NULL,

    -- ❗ URL больше не обязателен в БД (presigned протухает)
                        audio_url     TEXT NULL,
                        stream_url    TEXT NULL,
                        image_url     TEXT NULL,

                        is_favorite   BOOLEAN NOT NULL DEFAULT false,

                        created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

                        UNIQUE(job_id, suno_audio_id)
);

-- Индексы под выборки
CREATE INDEX tracks_job_id_idx ON tracks(job_id);
CREATE INDEX tracks_job_created_desc_idx ON tracks(job_id, created_at DESC);

-- Избранное: частичный индекс ускоряет favorites
CREATE INDEX tracks_favorite_true_created_desc_idx
    ON tracks(created_at DESC)
    WHERE is_favorite = true;

-- Уникальность объектов в MinIO (если key задан)
CREATE UNIQUE INDEX tracks_audio_obj_uq
    ON tracks(audio_bucket, audio_key)
    WHERE audio_key IS NOT NULL;

CREATE UNIQUE INDEX tracks_image_obj_uq
    ON tracks(image_bucket, image_key)
    WHERE image_key IS NOT NULL;
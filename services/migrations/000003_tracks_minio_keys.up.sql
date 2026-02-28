-- 000003_tracks_minio_keys.up.sql

ALTER TABLE tracks
    ADD COLUMN IF NOT EXISTS audio_bucket TEXT NOT NULL DEFAULT 'audio',
    ADD COLUMN IF NOT EXISTS audio_key    TEXT NULL,
    ADD COLUMN IF NOT EXISTS image_bucket TEXT NOT NULL DEFAULT 'images',
    ADD COLUMN IF NOT EXISTS image_key    TEXT NULL;


-- Уникальность объектов в MinIO (если key задан)
CREATE UNIQUE INDEX IF NOT EXISTS tracks_audio_obj_uq
    ON tracks(audio_bucket, audio_key)
    WHERE audio_key IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS tracks_image_obj_uq
    ON tracks(image_bucket, image_key)
    WHERE image_key IS NOT NULL;

-- Быстрее доставать треки по job
CREATE INDEX IF NOT EXISTS tracks_job_created_desc_idx
    ON tracks(job_id, created_at DESC);

-- Быстрый список избранного (частичный индекс)
CREATE INDEX IF NOT EXISTS tracks_favorite_true_created_desc_idx
    ON tracks(created_at DESC)
    WHERE is_favorite = true;
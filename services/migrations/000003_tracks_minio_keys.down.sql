-- 000003_tracks_minio_keys.down.sql

DROP INDEX IF EXISTS tracks_favorite_true_created_desc_idx;
DROP INDEX IF EXISTS tracks_job_created_desc_idx;

DROP INDEX IF EXISTS tracks_image_obj_uq;
DROP INDEX IF EXISTS tracks_audio_obj_uq;

-- Возвращаем audio_url обратно в NOT NULL (нужно, чтобы не упало)
UPDATE tracks SET audio_url = '' WHERE audio_url IS NULL;
ALTER TABLE tracks ALTER COLUMN audio_url SET NOT NULL;

ALTER TABLE tracks
DROP COLUMN IF EXISTS image_key,
  DROP COLUMN IF EXISTS image_bucket,
  DROP COLUMN IF EXISTS audio_key,
  DROP COLUMN IF EXISTS audio_bucket;
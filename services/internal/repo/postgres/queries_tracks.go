package postgres

const qTrackUpsert = `
INSERT INTO tracks (
  id, job_id,
  suno_audio_id, title, tags,
  duration_sec,
  audio_bucket, audio_key,
  image_bucket, image_key,
  is_favorite
)
VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
ON CONFLICT (job_id, suno_audio_id) DO UPDATE
SET
  title = EXCLUDED.title,
  tags = EXCLUDED.tags,
  duration_sec = EXCLUDED.duration_sec,

  -- не затираем существующие значения NULL-ом
  audio_bucket = CASE
    WHEN EXCLUDED.audio_key IS NULL THEN tracks.audio_bucket
    ELSE EXCLUDED.audio_bucket
  END,
  audio_key = COALESCE(EXCLUDED.audio_key, tracks.audio_key),

  image_bucket = CASE
    WHEN EXCLUDED.image_key IS NULL THEN tracks.image_bucket
    ELSE EXCLUDED.image_bucket
  END,
  image_key = COALESCE(EXCLUDED.image_key, tracks.image_key)

RETURNING id;
`

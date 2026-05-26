package postgres

const trackColumns = "id, job_id, suno_audio_id, title, tags, duration_sec, audio_bucket, audio_key, image_bucket, image_key, audio_url, stream_url, image_url, is_favorite, created_at, updated_at"
const trackColumnsT = "t.id, t.job_id, t.suno_audio_id, t.title, t.tags, t.duration_sec, t.audio_bucket, t.audio_key, t.image_bucket, t.image_key, t.audio_url, t.stream_url, t.image_url, t.is_favorite, t.created_at, t.updated_at"

const qTrackUpsert = `
INSERT INTO tracks (
  id, job_id,
  suno_audio_id, title, tags,
  duration_sec,
  audio_bucket, audio_key,
  image_bucket, image_key,
  audio_url, stream_url, image_url,
  is_favorite
)
VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
ON CONFLICT (job_id, suno_audio_id) DO UPDATE
SET
  title = EXCLUDED.title,
  tags = EXCLUDED.tags,
  duration_sec = EXCLUDED.duration_sec,

  -- не затираем существующие значения NULL-ом
  audio_bucket = CASE
    WHEN EXCLUDED.audio_key IS NOT NULL THEN EXCLUDED.audio_bucket
    ELSE tracks.audio_bucket
  END,
  audio_key = CASE
    WHEN EXCLUDED.audio_key IS NOT NULL THEN EXCLUDED.audio_key
    ELSE tracks.audio_key
  END,

  image_bucket = CASE
    WHEN EXCLUDED.image_key IS NULL THEN tracks.image_bucket
    ELSE EXCLUDED.image_bucket
  END,
  image_key = COALESCE(EXCLUDED.image_key, tracks.image_key),
  audio_url = COALESCE(EXCLUDED.audio_url, tracks.audio_url),
  stream_url = COALESCE(EXCLUDED.stream_url, tracks.stream_url),
  image_url = COALESCE(EXCLUDED.image_url, tracks.image_url)

RETURNING ` + trackColumns + `;
`

const qTrackGet = "SELECT " + trackColumns + " FROM tracks WHERE id = $1;"
const qTracksByJobID = "SELECT " + trackColumns + " FROM tracks WHERE job_id = $1 ORDER BY created_at ASC;"

const qTrackDelete = `
DELETE FROM tracks t
USING jobs j
WHERE t.id = $1 AND t.job_id = j.id AND j.user_id = $2;
`

const qTrackSetFavorite = `
UPDATE tracks t
SET is_favorite = $3
FROM jobs j
WHERE t.id = $1 AND t.job_id = j.id AND j.user_id = $2;
`

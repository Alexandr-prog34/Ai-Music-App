package postgres

const qJobCreate = `
INSERT INTO jobs (
  id, user_id, status,
  prompt, custom_mode, style, title, instrumental, model, vocal_gender, negative_tags
)
VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
RETURNING id;
`

const qJobGet = `
SELECT
  id, user_id, status,
  prompt, custom_mode, style, title, instrumental, model, vocal_gender, negative_tags,
  suno_task_id, error,
  attempts, started_at, finished_at,
  created_at, updated_at
FROM jobs
WHERE id = $1;
`

// ВАЖНО: поиск по taskId для callback
const qJobGetByTaskID = `
SELECT
  id, user_id, status,
  prompt, custom_mode, style, title, instrumental, model, vocal_gender, negative_tags,
  suno_task_id, error,
  attempts, started_at, finished_at,
  created_at, updated_at
FROM jobs
WHERE suno_task_id = $1;
`

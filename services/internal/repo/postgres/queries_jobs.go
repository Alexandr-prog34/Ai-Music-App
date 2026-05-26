package postgres

const jobColumns = "id, user_id, status, prompt, custom_mode, style, title, instrumental, model, vocal_gender, negative_tags, suno_task_id, error, attempts, started_at, finished_at, created_at, updated_at"
const jobColumnsJ = "j.id, j.user_id, j.status, j.prompt, j.custom_mode, j.style, j.title, j.instrumental, j.model, j.vocal_gender, j.negative_tags, j.suno_task_id, j.error, j.attempts, j.started_at, j.finished_at, j.created_at, j.updated_at"

const qJobCreate = `
INSERT INTO jobs (
  id, user_id, status,
  prompt, custom_mode, style, title, instrumental, model, vocal_gender, negative_tags
)
VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
RETURNING id;
`

const qJobUpdate = `
UPDATE jobs
SET
  status = $2,
  suno_task_id = $3,
  error = $4,
  attempts = $5,
  started_at = $6,
  finished_at = $7
WHERE id = $1
RETURNING id;
`

const qJobGet = "SELECT " + jobColumns + " FROM jobs WHERE id = $1;"

// ВАЖНО: поиск по taskId для callback
const qJobGetByTaskID = "SELECT " + jobColumns + " FROM jobs WHERE suno_task_id = $1;"

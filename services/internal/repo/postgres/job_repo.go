package postgres

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/google/uuid"
)

type JobRepo struct {
	db *sql.DB
}

func NewJobRepo(db *sql.DB) *JobRepo { return &JobRepo{db: db} }

type rowScanner interface{ Scan(dest ...any) error }

// scanJob — маппинг row -> domain.Job
func scanJob(s rowScanner) (domain.Job, error) {
	var j domain.Job

	var status string
	var model string

	var style, title, vocal, neg sql.NullString
	var taskID, errMsg sql.NullString
	var started, finished sql.NullTime

	err := s.Scan(
		&j.ID, &j.UserID, &status,
		&j.Params.Prompt, &j.Params.CustomMode, &style, &title, &j.Params.Instrumental, &model, &vocal, &neg,
		&taskID, &errMsg,
		&j.Attempts, &started, &finished,
		&j.CreatedAt, &j.UpdatedAt,
	)
	if err != nil {
		return domain.Job{}, err
	}

	j.Status = domain.JobStatus(status)
	j.Params.Model = domain.SunoModel(model)

	if style.Valid {
		v := style.String
		j.Params.Style = &v
	}
	if title.Valid {
		v := title.String
		j.Params.Title = &v
	}
	if vocal.Valid {
		vg := domain.VocalGender(vocal.String)
		j.Params.VocalGender = &vg
	}
	if neg.Valid {
		v := neg.String
		j.Params.NegativeTags = &v
	}

	if taskID.Valid {
		v := taskID.String
		j.SunoTaskID = &v
	}
	if errMsg.Valid {
		v := errMsg.String
		j.Error = &v
	}
	if started.Valid {
		t := started.Time
		j.StartedAt = &t
	}
	if finished.Valid {
		t := finished.Time
		j.FinishedAt = &t
	}

	return j, nil
}

func (r *JobRepo) CreateJob(ctx context.Context, job domain.Job) (domain.Job, error) {
	var style, title, vocal, neg any
	if job.Params.Style != nil {
		style = *job.Params.Style
	}
	if job.Params.Title != nil {
		title = *job.Params.Title
	}
	if job.Params.VocalGender != nil {
		vocal = job.Params.VocalGender.String()
	}
	if job.Params.NegativeTags != nil {
		neg = *job.Params.NegativeTags
	}

	// create
	var id uuid.UUID
	if err := r.db.QueryRowContext(ctx, qJobCreate,
		job.ID, job.UserID, job.Status.String(),
		job.Params.Prompt, job.Params.CustomMode, style, title, job.Params.Instrumental,
		job.Params.Model.String(), vocal, neg,
	).Scan(&id); err != nil {
		return domain.Job{}, err
	}

	// читаем свежую запись (чтобы получить created_at/updated_at)
	return r.GetJob(ctx, id)
}

func (r *JobRepo) UpdateJob(ctx context.Context, job domain.Job) (domain.Job, error) {
	var taskID any
	if job.SunoTaskID != nil {
		taskID = *job.SunoTaskID
	}
	var errMsg any
	if job.Error != nil {
		errMsg = *job.Error
	}
	var started any
	if job.StartedAt != nil {
		started = *job.StartedAt
	}
	var finished any
	if job.FinishedAt != nil {
		finished = *job.FinishedAt
	}

	const q = `
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
	var id uuid.UUID
	if err := r.db.QueryRowContext(ctx, q,
		job.ID,
		job.Status.String(),
		taskID,
		errMsg,
		job.Attempts,
		started,
		finished,
	).Scan(&id); err != nil {
		return domain.Job{}, err
	}

	return r.GetJob(ctx, id)
}

func (r *JobRepo) GetJob(ctx context.Context, id uuid.UUID) (domain.Job, error) {
	row := r.db.QueryRowContext(ctx, qJobGet, id)
	j, err := scanJob(row)
	if err == sql.ErrNoRows {
		return domain.Job{}, fmt.Errorf("%w", domain.ErrJobNotFound)
	}
	return j, err
}

func (r *JobRepo) GetJobBySunoTaskID(ctx context.Context, taskID string) (domain.Job, error) {
	row := r.db.QueryRowContext(ctx, qJobGetByTaskID, taskID)
	j, err := scanJob(row)
	if err == sql.ErrNoRows {
		return domain.Job{}, fmt.Errorf("%w", domain.ErrJobNotFound)
	}
	return j, err
}

// ListJobs — принимает deviceID (installID) как у тебя в ports.
// Мы JOIN’имся на users.install_id, чтобы найти jobs.
func (r *JobRepo) ListJobs(ctx context.Context, userID uuid.UUID, status *domain.JobStatus, limit, offset int) ([]domain.Job, int, error) {
	where := ` WHERE j.user_id = $1 `
	args := []any{userID}

	if status != nil {
		where += ` AND j.status = $2 `
		args = append(args, status.String())
	}

	countSQL := `SELECT COUNT(*) FROM jobs j` + where

	var total int
	if err := r.db.QueryRowContext(ctx, countSQL, args...).Scan(&total); err != nil {
		return nil, 0, err
	}

	selectSQL := `
SELECT
  j.id, j.user_id, j.status,
  j.prompt, j.custom_mode, j.style, j.title, j.instrumental, j.model, j.vocal_gender, j.negative_tags,
  j.suno_task_id, j.error,
  j.attempts, j.started_at, j.finished_at,
  j.created_at, j.updated_at
FROM jobs j
` + where + `
ORDER BY j.created_at DESC
LIMIT $` + fmt.Sprint(len(args)+1) + ` OFFSET $` + fmt.Sprint(len(args)+2)

	args = append(args, limit, offset)

	rows, err := r.db.QueryContext(ctx, selectSQL, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	out := make([]domain.Job, 0, limit)
	for rows.Next() {
		j, err := scanJob(rows)
		if err != nil {
			return nil, 0, err
		}
		out = append(out, j)
	}
	return out, total, rows.Err()
}

package postgres

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	sq "github.com/Masterminds/squirrel"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type JobRepo struct {
	db *sqlx.DB
}

func NewJobRepo(db *sql.DB) *JobRepo { return &JobRepo{db: sqlx.NewDb(db, "pgx")} }

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
		return domain.Job{}, fmt.Errorf("scan job: %w", err)
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
	if err := r.db.QueryRowxContext(ctx, qJobCreate,
		job.ID, job.UserID, job.Status.String(),
		job.Params.Prompt, job.Params.CustomMode, style, title, job.Params.Instrumental,
		job.Params.Model.String(), vocal, neg,
	).Scan(&id); err != nil {
		return domain.Job{}, fmt.Errorf("create job: %w", err)
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

	var id uuid.UUID
	if err := r.db.QueryRowxContext(ctx, qJobUpdate,
		job.ID,
		job.Status.String(),
		taskID,
		errMsg,
		job.Attempts,
		started,
		finished,
	).Scan(&id); err != nil {
		return domain.Job{}, fmt.Errorf("update job: %w", err)
	}

	return r.GetJob(ctx, id)
}

func (r *JobRepo) GetJob(ctx context.Context, id uuid.UUID) (domain.Job, error) {
	row := r.db.QueryRowxContext(ctx, qJobGet, id)
	j, err := scanJob(row)
	if errors.Is(err, sql.ErrNoRows) {
		return domain.Job{}, fmt.Errorf("%w", domain.ErrJobNotFound)
	}
	if err != nil {
		return domain.Job{}, fmt.Errorf("get job: %w", err)
	}
	return j, nil
}

func (r *JobRepo) GetJobBySunoTaskID(ctx context.Context, taskID string) (domain.Job, error) {
	row := r.db.QueryRowxContext(ctx, qJobGetByTaskID, taskID)
	j, err := scanJob(row)
	if errors.Is(err, sql.ErrNoRows) {
		return domain.Job{}, fmt.Errorf("%w", domain.ErrJobNotFound)
	}
	if err != nil {
		return domain.Job{}, fmt.Errorf("get job by suno task id: %w", err)
	}
	return j, nil
}

// ListJobs — принимает deviceID (installID) как у тебя в ports.
// Мы JOIN’имся на users.install_id, чтобы найти jobs.
func (r *JobRepo) ListJobs(ctx context.Context, userID uuid.UUID, status *domain.JobStatus, limit, offset int) ([]domain.Job, int, error) {
	const maxLimit = 100
	if limit <= 0 || limit > maxLimit {
		limit = maxLimit
	}
	if offset < 0 {
		offset = 0
	}

	sb := sq.StatementBuilder.PlaceholderFormat(sq.Dollar)

	countQ := sb.Select("COUNT(*)").
		From("jobs j").
		Where(sq.Eq{"j.user_id": userID})
	if status != nil {
		countQ = countQ.Where(sq.Eq{"j.status": status.String()})
	}

	countSQL, args, err := countQ.ToSql()
	if err != nil {
		return nil, 0, fmt.Errorf("build count query: %w", err)
	}

	var total int
	if err := r.db.QueryRowxContext(ctx, countSQL, args...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("count jobs: %w", err)
	}

	listQ := sb.Select(jobColumnsJ).
		From("jobs j").
		Where(sq.Eq{"j.user_id": userID}).
		OrderBy("j.created_at DESC").
		Limit(uint64(limit)).
		Offset(uint64(offset))
	if status != nil {
		listQ = listQ.Where(sq.Eq{"j.status": status.String()})
	}

	selectSQL, args, err := listQ.ToSql()
	if err != nil {
		return nil, 0, fmt.Errorf("build list query: %w", err)
	}

	rows, err := r.db.QueryxContext(ctx, selectSQL, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("list jobs: %w", err)
	}
	defer rows.Close()

	out := make([]domain.Job, 0, limit)
	for rows.Next() {
		j, err := scanJob(rows)
		if err != nil {
			return nil, 0, fmt.Errorf("scan list jobs: %w", err)
		}
		out = append(out, j)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("list jobs rows: %w", err)
	}
	return out, total, nil
}

package postgres

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	"github.com/google/uuid"
)

type TrackRepo struct {
	db *sql.DB
}

func NewTrackRepo(db *sql.DB) *TrackRepo { return &TrackRepo{db: db} }

func scanTrack(s rowScanner) (domain.Track, error) {
	var t domain.Track

	var tags sql.NullString

	var audioBucket string
	var audioKey sql.NullString
	var imageBucket sql.NullString
	var imageKey sql.NullString

	err := s.Scan(
		&t.ID, &t.JobID, &t.SunoAudioID, &t.Title, &tags, &t.DurationSec,
		&audioBucket, &audioKey,
		&imageBucket, &imageKey,
		&t.IsFavorite, &t.CreatedAt,
	)
	if err != nil {
		return domain.Track{}, err
	}

	if tags.Valid {
		v := tags.String
		t.Tags = &v
	}

	t.AudioBucket = audioBucket
	if audioKey.Valid {
		t.AudioKey = audioKey.String
	}

	// обложку выставляем только если оба значения реально есть
	if imageBucket.Valid && imageKey.Valid {
		b := imageBucket.String
		k := imageKey.String
		t.ImageBucket = &b
		t.ImageKey = &k
	}

	return t, nil
}

func (r *TrackRepo) CreateTrack(ctx context.Context, track domain.Track) (domain.Track, error) {
	var tags any
	if track.Tags != nil {
		tags = *track.Tags
	}

	// image_bucket в БД NOT NULL, поэтому всегда строка
	const defaultImageBucket = "images"
	imgBucket := any(defaultImageBucket)
	var imgKey any // nil по умолчанию

	// считаем, что обложка есть, только если есть key
	if track.ImageKey != nil {
		imgKey = *track.ImageKey
		if track.ImageBucket != nil && *track.ImageBucket != "" {
			imgBucket = *track.ImageBucket
		}
	}

	var id uuid.UUID
	if err := r.db.QueryRowContext(ctx, qTrackUpsert,
		track.ID, track.JobID,
		track.SunoAudioID, track.Title, tags,
		track.DurationSec,
		track.AudioBucket, track.AudioKey,
		imgBucket, imgKey,
		track.IsFavorite,
	).Scan(&id); err != nil {
		return domain.Track{}, err
	}

	return r.GetTrack(ctx, id)
}

func (r *TrackRepo) GetTrack(ctx context.Context, id uuid.UUID) (domain.Track, error) {
	const q = `
SELECT
  id, job_id, suno_audio_id, title, tags, duration_sec,
  audio_bucket, audio_key, image_bucket, image_key,
  is_favorite, created_at
FROM tracks
WHERE id = $1;
`
	row := r.db.QueryRowContext(ctx, q, id)
	t, err := scanTrack(row)
	if err == sql.ErrNoRows {
		return domain.Track{}, fmt.Errorf("%w", domain.ErrTrackNotFound)
	}
	return t, err
}

// ВНИМАНИЕ: как и с jobs — ListTracks принимает deviceID (installID) из ports,
// значит фильтруем через JOIN users.install_id
func (r *TrackRepo) ListTracks(ctx context.Context, userID uuid.UUID, favorite *bool, limit, offset int) ([]domain.Track, int, error) {
	where := ` WHERE j.user_id = $1 `
	args := []any{userID}

	if favorite != nil {
		where += ` AND t.is_favorite = $2 `
		args = append(args, *favorite)
	}

	countSQL := `SELECT COUNT(*) FROM tracks t JOIN jobs j ON j.id=t.job_id` + where

	var total int
	if err := r.db.QueryRowContext(ctx, countSQL, args...).Scan(&total); err != nil {
		return nil, 0, err
	}

	selectSQL := `
SELECT
  t.id, t.job_id, t.suno_audio_id, t.title, t.tags, t.duration_sec,
  t.audio_bucket, t.audio_key, t.image_bucket, t.image_key,
  t.is_favorite, t.created_at
FROM tracks t
JOIN jobs j ON j.id = t.job_id
` + where + `
ORDER BY t.created_at DESC
LIMIT $` + fmt.Sprint(len(args)+1) + ` OFFSET $` + fmt.Sprint(len(args)+2)

	args = append(args, limit, offset)

	rows, err := r.db.QueryContext(ctx, selectSQL, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	out := make([]domain.Track, 0, limit)
	for rows.Next() {
		t, err := scanTrack(rows)
		if err != nil {
			return nil, 0, err
		}
		out = append(out, t)
	}
	return out, total, rows.Err()
}

// ⚠️ ВНИМАНИЕ по безопасности:
// DeleteTrack/SetFavorite без deviceID/userID могут менять чужие треки.
// Я оставил как у тебя в ports, но настоятельно советую добавить deviceID/userID в сигнатуру.
func (r *TrackRepo) DeleteTrack(ctx context.Context, id uuid.UUID, userID uuid.UUID) error {
	res, err := r.db.ExecContext(ctx, `
DELETE FROM tracks t
USING jobs j
WHERE t.id = $1 AND t.job_id = j.id AND j.user_id = $2
`, id, userID)
	if err != nil {
		return err
	}

	ra, _ := res.RowsAffected()
	if ra == 0 {
		return fmt.Errorf("%w", domain.ErrTrackNotFound)
	}
	return nil
}

func (r *TrackRepo) SetFavorite(ctx context.Context, id uuid.UUID, userID uuid.UUID, favorite bool) error {
	res, err := r.db.ExecContext(ctx, `
UPDATE tracks t
SET is_favorite = $3
FROM jobs j
WHERE t.id = $1 AND t.job_id = j.id AND j.user_id = $2
`, id, userID, favorite)
	if err != nil {
		return err
	}

	ra, _ := res.RowsAffected()
	if ra == 0 {
		return fmt.Errorf("%w", domain.ErrTrackNotFound)
	}
	return nil
}

package postgres

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/domain"
	sq "github.com/Masterminds/squirrel"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type TrackRepo struct {
	db *sqlx.DB
}

func NewTrackRepo(db *sql.DB) *TrackRepo { return &TrackRepo{db: sqlx.NewDb(db, "pgx")} }

func scanTrack(s rowScanner) (domain.Track, error) {
	var t domain.Track

	var tags sql.NullString
	var audioURL sql.NullString
	var streamURL sql.NullString
	var imageURL sql.NullString

	var audioBucket string
	var audioKey sql.NullString
	var imageBucket sql.NullString
	var imageKey sql.NullString
	var durationSec float64

	err := s.Scan(
		&t.ID, &t.JobID, &t.SunoAudioID, &t.Title, &tags, &durationSec,
		&audioBucket, &audioKey,
		&imageBucket, &imageKey,
		&audioURL, &streamURL, &imageURL,
		&t.IsFavorite, &t.CreatedAt, &t.UpdatedAt,
	)
	if err != nil {
		return domain.Track{}, fmt.Errorf("scan track: %w", err)
	}

	t.Duration = time.Duration(durationSec * float64(time.Second))

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
	if audioURL.Valid {
		t.AudioURL = audioURL.String
	}
	if streamURL.Valid {
		v := streamURL.String
		t.StreamURL = &v
	}
	if imageURL.Valid {
		v := imageURL.String
		t.ImageURL = &v
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

	var audioURL any
	if track.AudioURL != "" {
		audioURL = track.AudioURL
	}
	var streamURL any
	if track.StreamURL != nil {
		streamURL = *track.StreamURL
	}
	var imageURL any
	if track.ImageURL != nil {
		imageURL = *track.ImageURL
	}

	row := r.db.QueryRowxContext(ctx, qTrackUpsert,
		track.ID, track.JobID,
		track.SunoAudioID, track.Title, tags,
		track.Duration.Seconds(),
		track.AudioBucket, track.AudioKey,
		imgBucket, imgKey,
		audioURL, streamURL, imageURL,
		track.IsFavorite,
	)
	out, err := scanTrack(row)
	if err != nil {
		return domain.Track{}, fmt.Errorf("create track: %w", err)
	}

	return out, nil
}

func (r *TrackRepo) GetTrack(ctx context.Context, id uuid.UUID) (domain.Track, error) {
	row := r.db.QueryRowxContext(ctx, qTrackGet, id)
	t, err := scanTrack(row)
	if errors.Is(err, sql.ErrNoRows) {
		return domain.Track{}, fmt.Errorf("%w", domain.ErrTrackNotFound)
	}
	if err != nil {
		return domain.Track{}, fmt.Errorf("get track: %w", err)
	}
	return t, nil
}

func (r *TrackRepo) ListTracksByJobID(ctx context.Context, jobID uuid.UUID) ([]domain.Track, error) {
	rows, err := r.db.QueryxContext(ctx, qTracksByJobID, jobID)
	if err != nil {
		return nil, fmt.Errorf("list tracks by job: %w", err)
	}
	defer rows.Close()

	tracks := make([]domain.Track, 0)
	for rows.Next() {
		track, scanErr := scanTrack(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan track by job: %w", scanErr)
		}
		tracks = append(tracks, track)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("list tracks by job rows: %w", err)
	}
	return tracks, nil
}

// ВНИМАНИЕ: как и с jobs — ListTracks принимает deviceID (installID) из ports,
// значит фильтруем через JOIN users.install_id
func (r *TrackRepo) ListTracks(ctx context.Context, userID uuid.UUID, favorite *bool, limit, offset int) ([]domain.Track, int, error) {
	const maxLimit = 100
	if limit <= 0 || limit > maxLimit {
		limit = maxLimit
	}
	if offset < 0 {
		offset = 0
	}

	sb := sq.StatementBuilder.PlaceholderFormat(sq.Dollar)

	countQ := sb.Select("COUNT(*)").
		From("tracks t").
		Join("jobs j ON j.id = t.job_id").
		Where(sq.Eq{"j.user_id": userID})
	if favorite != nil {
		countQ = countQ.Where(sq.Eq{"t.is_favorite": *favorite})
	}

	countSQL, args, err := countQ.ToSql()
	if err != nil {
		return nil, 0, fmt.Errorf("build count query: %w", err)
	}

	var total int
	if err := r.db.QueryRowxContext(ctx, countSQL, args...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("count tracks: %w", err)
	}

	listQ := sb.Select(trackColumnsT).
		From("tracks t").
		Join("jobs j ON j.id = t.job_id").
		Where(sq.Eq{"j.user_id": userID}).
		OrderBy("t.created_at DESC").
		Limit(uint64(limit)).
		Offset(uint64(offset))
	if favorite != nil {
		listQ = listQ.Where(sq.Eq{"t.is_favorite": *favorite})
	}

	selectSQL, args, err := listQ.ToSql()
	if err != nil {
		return nil, 0, fmt.Errorf("build list query: %w", err)
	}

	rows, err := r.db.QueryxContext(ctx, selectSQL, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("list tracks: %w", err)
	}
	defer rows.Close()

	out := make([]domain.Track, 0, limit)
	for rows.Next() {
		t, err := scanTrack(rows)
		if err != nil {
			return nil, 0, fmt.Errorf("scan list tracks: %w", err)
		}
		out = append(out, t)
	}
	if err := rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("list tracks rows: %w", err)
	}
	return out, total, nil
}

// ⚠️ ВНИМАНИЕ по безопасности:
// DeleteTrack/SetFavorite без deviceID/userID могут менять чужие треки.
// Я оставил как у тебя в ports, но настоятельно советую добавить deviceID/userID в сигнатуру.
func (r *TrackRepo) DeleteTrack(ctx context.Context, id uuid.UUID, userID uuid.UUID) error {
	res, err := r.db.ExecContext(ctx, qTrackDelete, id, userID)
	if err != nil {
		return fmt.Errorf("delete track: %w", err)
	}

	ra, _ := res.RowsAffected()
	if ra == 0 {
		return fmt.Errorf("%w", domain.ErrTrackNotFound)
	}
	return nil
}

func (r *TrackRepo) SetFavorite(ctx context.Context, id uuid.UUID, userID uuid.UUID, favorite bool) error {
	res, err := r.db.ExecContext(ctx, qTrackSetFavorite, id, userID, favorite)
	if err != nil {
		return fmt.Errorf("set favorite: %w", err)
	}

	ra, _ := res.RowsAffected()
	if ra == 0 {
		return fmt.Errorf("%w", domain.ErrTrackNotFound)
	}
	return nil
}

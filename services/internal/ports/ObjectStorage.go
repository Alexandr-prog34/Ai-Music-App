package ports

import (
	"context"
	"time"
)

type ObjectStorage interface {
	DefaultBucket() string
	UploadFromURL(ctx context.Context, sourceURL string, objectKey string) (string, error)
	PresignGetURL(ctx context.Context, bucket string, objectKey string, expiry time.Duration) (string, error)
	DeleteObject(ctx context.Context, bucket string, objectKey string) error
}

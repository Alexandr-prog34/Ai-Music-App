package storage

import (
	"context"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"

	"github.com/AI-Music-App001/Ai-Music-Generator/services/internal/ports"
)

const defaultPresignTTL = 15 * time.Minute

type Config struct {
	Endpoint       string
	PublicEndpoint string
	AccessKey      string
	SecretKey      string
	Bucket         string
}

type MinIOObjectStorage struct {
	client        *minio.Client
	presignClient *minio.Client
	bucket        string
}

func NewMinIOObjectStorage(ctx context.Context, cfg Config) (ports.ObjectStorage, error) {
	endpoint, secure, err := normalizeEndpoint(cfg.Endpoint)
	if err != nil {
		return nil, err
	}
	if strings.TrimSpace(cfg.Bucket) == "" {
		return nil, fmt.Errorf("s3 bucket is empty")
	}

	client, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(strings.TrimSpace(cfg.AccessKey), strings.TrimSpace(cfg.SecretKey), ""),
		Secure: secure,
		Region: "us-east-1",
	})
	if err != nil {
		return nil, fmt.Errorf("create minio client: %w", err)
	}

	publicEndpoint := strings.TrimSpace(cfg.PublicEndpoint)
	if publicEndpoint == "" {
		publicEndpoint = cfg.Endpoint
	}

	publicHost, publicSecure, err := normalizeEndpoint(publicEndpoint)
	if err != nil {
		return nil, err
	}

	presignClient, err := minio.New(publicHost, &minio.Options{
		Creds:  credentials.NewStaticV4(strings.TrimSpace(cfg.AccessKey), strings.TrimSpace(cfg.SecretKey), ""),
		Secure: publicSecure,
		Region: "us-east-1",
	})
	if err != nil {
		return nil, fmt.Errorf("create minio presign client: %w", err)
	}

	store := &MinIOObjectStorage{
		client:        client,
		presignClient: presignClient,
		bucket:        strings.TrimSpace(cfg.Bucket),
	}
	if err := store.ensureBucket(ctx); err != nil {
		return nil, err
	}

	return store, nil
}

func (s *MinIOObjectStorage) DefaultBucket() string {
	return s.bucket
}

func (s *MinIOObjectStorage) UploadFromURL(ctx context.Context, sourceURL string, objectKey string) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, sourceURL, nil)
	if err != nil {
		return "", fmt.Errorf("build source request: %w", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("download source object: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("download source object: unexpected status %d", resp.StatusCode)
	}

	size := resp.ContentLength
	contentType := strings.TrimSpace(resp.Header.Get("Content-Type"))
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	_, err = s.client.PutObject(ctx, s.bucket, strings.TrimSpace(objectKey), resp.Body, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", fmt.Errorf("upload object to minio: %w", err)
	}

	return s.bucket, nil
}

func (s *MinIOObjectStorage) PresignGetURL(ctx context.Context, bucket string, objectKey string, expiry time.Duration) (string, error) {
	if strings.TrimSpace(bucket) == "" {
		bucket = s.bucket
	}
	if expiry <= 0 {
		expiry = defaultPresignTTL
	}

	client := s.client
	if s.presignClient != nil {
		client = s.presignClient
	}

	u, err := client.PresignedGetObject(ctx, bucket, strings.TrimSpace(objectKey), expiry, nil)
	if err != nil {
		return "", fmt.Errorf("presign object: %w", err)
	}
	return u.String(), nil
}

func (s *MinIOObjectStorage) DeleteObject(ctx context.Context, bucket string, objectKey string) error {
	if strings.TrimSpace(bucket) == "" {
		bucket = s.bucket
	}

	if err := s.client.RemoveObject(ctx, bucket, strings.TrimSpace(objectKey), minio.RemoveObjectOptions{}); err != nil {
		return fmt.Errorf("remove object from minio: %w", err)
	}
	return nil
}

func (s *MinIOObjectStorage) ensureBucket(ctx context.Context) error {
	exists, err := s.client.BucketExists(ctx, s.bucket)
	if err != nil {
		return fmt.Errorf("check bucket exists: %w", err)
	}
	if exists {
		return nil
	}
	if err := s.client.MakeBucket(ctx, s.bucket, minio.MakeBucketOptions{}); err != nil {
		return fmt.Errorf("make bucket: %w", err)
	}
	return nil
}

func normalizeEndpoint(raw string) (string, bool, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return "", false, fmt.Errorf("s3 endpoint is empty")
	}

	if strings.HasPrefix(raw, "http://") || strings.HasPrefix(raw, "https://") {
		parsed, err := url.Parse(raw)
		if err != nil {
			return "", false, fmt.Errorf("parse s3 endpoint: %w", err)
		}
		return parsed.Host, parsed.Scheme == "https", nil
	}

	return raw, false, nil
}

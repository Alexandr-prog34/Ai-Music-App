package postgres

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"
)

type PoolConfig struct {
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
	ConnMaxIdleTime time.Duration
	PingTimeout     time.Duration
}

func DefaultPoolConfig() PoolConfig {
	return PoolConfig{
		MaxOpenConns:    10,
		MaxIdleConns:    10,
		ConnMaxLifetime: 30 * time.Minute,
		ConnMaxIdleTime: 5 * time.Minute,
		PingTimeout:     3 * time.Second,
	}
}

func (c PoolConfig) withDefaults() PoolConfig {
	d := DefaultPoolConfig()
	if c.MaxOpenConns <= 0 {
		c.MaxOpenConns = d.MaxOpenConns
	}
	if c.MaxIdleConns <= 0 {
		c.MaxIdleConns = d.MaxIdleConns
	}
	if c.ConnMaxLifetime <= 0 {
		c.ConnMaxLifetime = d.ConnMaxLifetime
	}
	if c.ConnMaxIdleTime <= 0 {
		c.ConnMaxIdleTime = d.ConnMaxIdleTime
	}
	if c.PingTimeout <= 0 {
		c.PingTimeout = d.PingTimeout
	}
	return c
}

func Open(ctx context.Context, dsn string, cfg PoolConfig) (*sql.DB, error) {
	if ctx == nil {
		ctx = context.Background()
	}
	cfg = cfg.withDefaults()

	db, err := sql.Open("pgx", dsn) // драйвер pgx через database/sql
	if err != nil {
		return nil, err
	}

	// базовые настройки пула (можно потом тюнить)
	db.SetMaxOpenConns(cfg.MaxOpenConns)
	db.SetMaxIdleConns(cfg.MaxIdleConns)
	db.SetConnMaxLifetime(cfg.ConnMaxLifetime)
	db.SetConnMaxIdleTime(cfg.ConnMaxIdleTime)

	pingCtx, cancel := context.WithTimeout(ctx, cfg.PingTimeout)
	defer cancel()

	if err := db.PingContext(pingCtx); err != nil {
		_ = db.Close()
		return nil, fmt.Errorf("postgres ping failed: %w", err)
	}

	return db, nil
}

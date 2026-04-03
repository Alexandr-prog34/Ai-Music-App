ALTER TABLE tracks
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- Авто-обновление updated_at (используем set_updated_at() из init миграции).
DROP TRIGGER IF EXISTS tracks_set_updated_at ON tracks;
CREATE TRIGGER tracks_set_updated_at
    BEFORE UPDATE ON tracks
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();


DROP TRIGGER IF EXISTS tracks_set_updated_at ON tracks;
ALTER TABLE tracks
    DROP COLUMN IF EXISTS updated_at;


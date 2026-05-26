-- Сначала триггер/функция (иначе останутся после DROP TABLE)
DROP TRIGGER IF EXISTS jobs_set_updated_at ON jobs;
DROP FUNCTION IF EXISTS set_updated_at();

DROP TABLE IF EXISTS tracks;
DROP TABLE IF EXISTS jobs;
DROP TYPE IF EXISTS job_status;
DROP TABLE IF EXISTS users;

-- Extension можно не удалять (часто оставляют), но для чистого rollback:
-- DROP EXTENSION IF EXISTS "uuid-ossp";
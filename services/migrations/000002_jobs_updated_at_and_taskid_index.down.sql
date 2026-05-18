-- 000002_jobs_updated_at_and_taskid_index.down.sql

DROP TRIGGER IF EXISTS jobs_set_updated_at ON jobs;
DROP FUNCTION IF EXISTS set_updated_at();

DROP INDEX IF EXISTS jobs_suno_task_id_uq;
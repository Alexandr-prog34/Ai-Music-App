-- 000002_jobs_updated_at_and_taskid_index.up.sql

-- Быстрый поиск job по taskId + защита от дублей taskId
CREATE UNIQUE INDEX IF NOT EXISTS jobs_suno_task_id_uq
    ON jobs(suno_task_id)
    WHERE suno_task_id IS NOT NULL;

-- Авто-обновление updated_at при любом UPDATE jobs
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS jobs_set_updated_at ON jobs;

CREATE TRIGGER jobs_set_updated_at
    BEFORE UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();
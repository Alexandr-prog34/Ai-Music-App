package postgres

const qUserGetOrCreate = `
INSERT INTO users (id, install_id)
VALUES ($1, $2)
ON CONFLICT (install_id) DO UPDATE SET install_id = EXCLUDED.install_id
RETURNING id, install_id, created_at;
`

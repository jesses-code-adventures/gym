CREATE TABLE schema_migrations (version uint64,dirty bool);
CREATE UNIQUE INDEX version_unique ON schema_migrations (version);
CREATE TABLE workout (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at integer not null
);
CREATE TABLE sqlite_sequence(name,seq);
CREATE TABLE workout_portion(
    id  INTEGER PRIMARY KEY AUTOINCREMENT,
    workout_id INTEGER not null,
    created_at integer not null,
    category TEXT CHECK(category IN ('CARDIO', 'WEIGHTS')) not null
);

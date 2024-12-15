create table workout (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at integer not null
);

create table workout_portion(
    id  INTEGER PRIMARY KEY AUTOINCREMENT,
    workout_id INTEGER not null,
    created_at integer not null,
    category TEXT CHECK(category IN ('CARDIO', 'WEIGHTS')) not null
);

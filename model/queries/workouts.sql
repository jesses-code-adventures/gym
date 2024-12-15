-- name: GetWorkouts :many
select * from workout;

-- name: CreateWorkout :one
insert into workout (created_at) 
values (?)
returning *;

-- name: CreateWorkoutPortion :one
insert into workout_portion(workout_id, created_at, category)
values (?, ?, ?)
returning *;

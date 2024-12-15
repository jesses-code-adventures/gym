// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.18.0
// source: workouts.sql

package model

import (
	"context"
)

const createWorkout = `-- name: CreateWorkout :one
insert into workout (created_at) 
values (?)
returning id, created_at
`

func (q *Queries) CreateWorkout(ctx context.Context, createdAt int64) (Workout, error) {
	row := q.db.QueryRowContext(ctx, createWorkout, createdAt)
	var i Workout
	err := row.Scan(&i.ID, &i.CreatedAt)
	return i, err
}

const createWorkoutPortion = `-- name: CreateWorkoutPortion :one
insert into workout_portion(workout_id, created_at, category)
values (?, ?, ?)
returning id, workout_id, created_at, category
`

type CreateWorkoutPortionParams struct {
	WorkoutID int64
	CreatedAt int64
	Category  string
}

func (q *Queries) CreateWorkoutPortion(ctx context.Context, arg CreateWorkoutPortionParams) (WorkoutPortion, error) {
	row := q.db.QueryRowContext(ctx, createWorkoutPortion, arg.WorkoutID, arg.CreatedAt, arg.Category)
	var i WorkoutPortion
	err := row.Scan(
		&i.ID,
		&i.WorkoutID,
		&i.CreatedAt,
		&i.Category,
	)
	return i, err
}

const getWorkouts = `-- name: GetWorkouts :many
select id, created_at from workout
`

func (q *Queries) GetWorkouts(ctx context.Context) ([]Workout, error) {
	rows, err := q.db.QueryContext(ctx, getWorkouts)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []Workout
	for rows.Next() {
		var i Workout
		if err := rows.Scan(&i.ID, &i.CreatedAt); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

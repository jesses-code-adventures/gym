// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.18.0

package model

import ()

type Workout struct {
	ID        int64
	CreatedAt int64
}

type WorkoutPortion struct {
	ID        int64
	WorkoutID int64
	CreatedAt int64
	Category  string
}

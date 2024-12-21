package workout

import (
	"context"
	"database/sql"

	"github.com/jesses-code-adventures/gym/model"
	"github.com/rs/zerolog/log"
)

type WorkoutService struct {
	db      *sql.DB
	queries *model.Queries
}

func NewWorkoutService(db *sql.DB) WorkoutService {
	return WorkoutService{
		db:      db,
		queries: model.New(db),
	}
}

func (w *WorkoutService) GetWorkouts(ctx context.Context) []model.Workout {
	logger := log.Ctx(ctx).With().Logger()
	logger.Info().Msg("getting workouts")
	workouts, err := w.queries.GetWorkouts(ctx)
	if err != nil {
		logger.Error().Msgf("GetWorkouts error: %s", err.Error())
		return nil
	}
	return workouts
}

func (w *WorkoutService) CreateWorkout() {

}

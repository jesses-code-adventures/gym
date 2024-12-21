package main

import (
	"database/sql"
	"fmt"
	_ "github.com/glebarez/go-sqlite"
	"os"

	"github.com/joho/godotenv"
	"github.com/spf13/cobra"
)

type GymApp struct {
	author  string
	db      *sql.DB
	version string
}

// newRootCommand initializes the root command
func (a *GymApp) newRootCommand() *cobra.Command {
	rootCmd := &cobra.Command{
		Use:   "gym",
		Short: "My workout tracker.",
		Long:  "This application helps you keep track of your workouts from the CLI.",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("gym cli v%s by %s\n", a.version, a.author)
		},
	}
	return rootCmd
}

// newGetWorkoutsCommand initializes the get-workouts command
func (a *GymApp) newGetWorkoutsCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "get-workouts",
		Short: "Fetch and display a list of workouts.",
		Long:  "This command retrieves and displays a list of workouts, providing information on each workout in a readable format.",
		Run: func(cmd *cobra.Command, args []string) {
			workouts := []string{"Workout 1: Push-Ups", "Workout 2: Squats", "Workout 3: Pull-Ups"}
			fmt.Println("Your Workouts:")
			for _, workout := range workouts {
				fmt.Println(workout)
			}
		},
	}
}

// setupCommands wires up all commands to the root command
func (a *GymApp) setupCommands() *cobra.Command {
	rootCmd := a.newRootCommand()
	rootCmd.AddCommand(a.newGetWorkoutsCommand())
	// add other commands here
	return rootCmd
}

func main() {
	godotenv.Load()
	db, err := sql.Open("sqlite", ":memory:")
	if err != nil {
		panic(err)
	}
	app := GymApp{
		author:  os.Getenv("AUTHOR"),
		version: os.Getenv("VERSION"),
		db:      db,
	}
	if err := app.setupCommands().Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

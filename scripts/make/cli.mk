add-cli-command: ## Adds a CLI command to the codebase using cobra cli eg `make command=create-workout add-cli-command`
	@cobra-cli add $(command) 

ref-run: refresh run

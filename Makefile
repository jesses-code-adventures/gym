.PHONY: build run test d help

BUILD_SOURCE_FILE=main.go
OUTPUT_FILE:=build/gym

# HELP - will output the help for each task in the Makefile
# In sorted order.
# The width of the first column can be determined by the `width` value passed to awk
#
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html for the initial version.
#
help: ## This help.
	@grep -E -h "^[a-zA-Z_-]+:.*?## " $(MAKEFILE_LIST) \
	  | sort \
	  | awk -v width=36 'BEGIN {FS = ":.*?## "} {printf "\033[36m%-*s\033[0m %s\n", width, $$1, $$2}'

build: ## Build the executable and save to $(BUILD_SOURCE_FILE)
	@go build -o $(OUTPUT_FILE) $(BUILD_SOURCE_FILE)

run: ## Run the binary at $(BUILD_SOURCE_FILE)
	@$(OUTPUT_FILE)

test: ## Run the project's tests
	@go test ./...

d: build run ## Build and run the project

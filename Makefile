.PHONY: backup build ci commands-check d db-kill db-migrate db-reset db-run db-schema-dump dml-with-file dml help is-dirty migrate-create migrate-up refresh run schema test

GO:=go
SLEEP_TIME=0
SHELL=bash
PROJECT_ROOT:=$(shell git rev-parse --show-toplevel)
GIT_BRANCH:=$(shell git rev-parse --abbrev-ref HEAD | sed "s*/*-*g")
GIT_BRANCH_SANITISED:=$(shell git rev-parse --abbrev-ref HEAD | sed "s*/*-*g" | tr '[:upper:]' '[:lower:]')
ENV_CONTEXT ?= $(PROJECT_ROOT)/.local.env
LOCAL_ENV_MINE=$(PROJECT_ROOT)/.local.mine.env
GO_PROJECT_NAME:=$(shell $(GO) mod edit -json | jq -r .Module.Path | xargs basename)
OUTPUT_BIN:=build/$(GO_PROJECT_NAME)
OS_PLATFORM:=$(shell uname | sed s/-.*//)
-include $(ENV_CONTEXT) $(LOCAL_ENV_MINE)
MAKE_LIB:=$(PROJECT_ROOT)/scripts/make
-include $(MAKE_LIB)/cli.mk
-include $(MAKE_LIB)/local-db.mk
-include $(MAKE_LIB)/print.mk
MIGRATIONS_DIR:=$(PROJECT_ROOT)/migrations
SQLITE_DB_FILE=build/$(GO_PROJECT_NAME).sqlite
URI:=sqlite3://
DB_SCHEMA_OUTPUT_FILE=model/schema/$(GO_PROJECT_NAME).sql

pre-reqs: ## Install any dev dependencies
	@which cobra-cli > /dev/null 2>&1 || (echo "Installing cobra-cli..." && $(GO) install github.com/spf13/cobra-cli@latest)

commands-ls: ## Get a list of all the commands in the makefile.
	@grep -E -h "^[a-zA-Z_-]+:.*?## " $(MAKEFILE_LIST) \
		| sort \
		| awk -F ':' '{print $$1}'

gen: ## Run any codegen associated with the project
	@sqlc generate
	
build: gen ## Build the executable and save to $(OUTPUT_BIN)
	@$(GO) build -o $(OUTPUT_BIN)

run: ## Run the binary at $(OUTPUT_BIN)
	@echo "Running: $(OUTPUT_BIN) $(filter-out $@,$(MAKECMDGOALS)) $(MAKEFLAGS)"
	@$(OUTPUT_BIN) $(ARGS)

test: ## Run the project's tests
	@$(GO) test ./...

ci: build test ## Commands to run during CI

commands-check: ## check that you have the tools required to run locally
	@which sqlc > /dev/null 2>&1 || (echo "sqlc tool issue - please install to fix" && exit 1)
	@which sqlite3 > /dev/null 2>&1  || (echo "sqlite3 tool issue - please install to fix" && exit 1)
	@which migrate > /dev/null 2>&1  || (echo "go-migrate tool issue - please install to fix" && exit 1)

refresh: db-reset build ## Reset the db and rebuild the app

hrun: build ## Hot run (build and run) eg `make hrun -- ARGS=60`
	@$(MAKE) run -- ARGS=$(ARGS)

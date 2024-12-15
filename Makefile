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
MAIN_DIR:=$(PROJECT_ROOT)/cmd/$(GO_PROJECT_NAME)
BUILD_SOURCE_FILE=$(MAIN_DIR)/main.go
OUTPUT_BIN:=build/$(GO_PROJECT_NAME)
OS_PLATFORM:=$(shell uname | sed s/-.*//)
-include $(ENV_CONTEXT) $(LOCAL_ENV_MINE)
MAKE_LIB:=$(PROJECT_ROOT)/scripts/make
-include $(MAKE_LIB)/print.mk
MIGRATIONS_DIR:=$(PROJECT_ROOT)/migrations
SQLITE_DB_FILE=build/$(GO_PROJECT_NAME).sqlite
URI:=sqlite3://
DB_SCHEMA_OUTPUT_FILE=model/schema/$(GO_PROJECT_NAME).sql

commands-ls: ## Get a list of all the commands in the makefile.
	@grep -E -h "^[a-zA-Z_-]+:.*?## " $(MAKEFILE_LIST) \
		| sort \
		| awk -F ':' '{print $$1}'

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

gen:
	@sqlc generate

build: gen ## Build the executable and save to $(BUILD_SOURCE_FILE)
	@$(GO) build -o $(OUTPUT_BIN) $(BUILD_SOURCE_FILE)

run: ## Run the binary at $(BUILD_SOURCE_FILE)
	@$(OUTPUT_BIN)

test: ## Run the project's tests
	@$(GO) test ./...

d: build run ## Build and run the project

ci: build test ## Commands to run during CI

commands-check: ## check that you have the tools required to run locally
	@which sqlc > /dev/null 2>&1 || (echo "sqlc tool issue - use make init to fix" && exit 1)
	@which sqlite3 > /dev/null 2>&1  || (echo "moq tool issue - use make init to fix" && exit 1)

migrate-create: ## Create a new migration file.  Usage: make migrate-create NAME=<migration_name>
	 @migrate create -dir ./migrations/ -ext sql $(NAME)

migrate-up: ## Run local migration upto lastest version
	@migrate -database=$(URI)$(SQLITE_DB_FILE) -path=./migrations/ up

db-run: commands-check ## Locally - run the db:
	$(call dump_header, $(DEBUG_DEFAULT_HDR_WIDTH), $@, $(DEBUG_DEFAULT_HDR_CHAR), $(DEBUG_DEFAULT_HDR_FG))
	@if [ ! -f "$(SQLITE_DB_FILE)" ]; then \
		echo "SQLite database file not found. Creating..."; \
		sqlite3 "$(SQLITE_DB_FILE)" ".databases"; \
	else \
		echo "SQLite database file exists at $(SQLITE_DB_FILE)"; \
	fi
	@echo "SLEEP for $(SLEEP_TIME) seconds..." && sleep $(SLEEP_TIME)

db-migrate: commands-check ## Locally - populate the local db
	$(call dump_header, $(DEBUG_DEFAULT_HDR_WIDTH), $@, $(DEBUG_DEFAULT_HDR_CHAR), $(DEBUG_DEFAULT_HDR_FG))
	@echo "START migration to local DB to $(URI)$(SQLITE_DB_FILE)"
	@migrate \
		-path migrations \
		-database "$(URI)$(SQLITE_DB_FILE)" up
	@echo "Migration complete"

db-reset: db-kill db-run ## build a new DB image, kill the existing db container, create a new one and run the migration
	$(call dump_header, $(DEBUG_DEFAULT_HDR_WIDTH), $@, $(DEBUG_DEFAULT_HDR_CHAR), $(DEBUG_DEFAULT_HDR_FG))
	@echo "DB has been created at $(SQLITE_DB_FILE), setting up..."
	@$(MAKE) --no-print-directory db-migrate
	@$(MAKE) --no-print-directory db-schema-dump

refresh: db-reset build ## Reset the db and rebuild the app

db-kill: ## Remove the existing local db
	$(call dump_header, $(DEBUG_DEFAULT_HDR_WIDTH), $@, $(DEBUG_DEFAULT_HDR_CHAR), $(DEBUG_DEFAULT_HDR_FG))
	@echo "removing file at [$(SQLITE_DB_FILE)]"
	@rm -f "$(SQLITE_DB_FILE)"

backup: ## create a backup of the sqlite database
	$(eval LOCAL_DB_BACKUP_FILE=$(PROJECT_ROOT)/migrations/backups/backup.$(TIMESTAMP).sqlite)
	@mkdir -p migrations/backups
	@cp $(SQLITE_DB_FILE) $(LOCAL_DB_BACKUP_FILE)
	@echo "Backup written to: $(LOCAL_DB_BACKUP_FILE)"

schema: ## export the sqlite schema to a file
	$(eval LOCAL_DB_SCHEMA_BACKUP_FILE=$(PROJECT_ROOT)/migrations/backups/schema-backup.$(TIMESTAMP).sql)
	@mkdir -p migrations/backups
	@sqlite3 $(SQLITE_DB_FILE) .schema > $(LOCAL_DB_SCHEMA_BACKUP_FILE)
	@echo "Schema Backup written to: $(LOCAL_DB_SCHEMA_BACKUP_FILE)"

db-schema-dump: ## dump the schema to a specific location
	@echo "dumping schema"
	@sqlite3 $(SQLITE_DB_FILE) .schema > $(DB_SCHEMA_OUTPUT_FILE) 
	@echo "Schema dumped to: $(DB_SCHEMA_OUTPUT_FILE)"

describe-%: ## describe table structure (sqlite equivalent of `\d+`)
	@$(eval QUERY:="pragma table_info($*)")
	@$(MAKE) dml --no-print-directory QUERY=$(QUERY)

select-all-%: ## select all rows from a table
	@$(eval QUERY:='SELECT * FROM $(*)')
	@$(MAKE) dml --no-print-directory QUERY=$(QUERY)

is-dirty: ## get the status of the previous migration from the schema migration tables
	@$(eval QUERY:='SELECT * FROM schema_migrations;')
	@$(MAKE) dml --no-print-directory QUERY=$(QUERY)

dml: ## execute a single query against the sqlite database eg `make dml QUERY="select * from workout"`
	@sqlite3 $(SQLITE_DB_FILE) '$(QUERY)'

dml-with-file: ## execute script file against the sqlite database eg `make dml-with-file DML_FILE_PATH=path_to_file.sql`
	$(call dump_header, $(DEBUG_DEFAULT_HDR_WIDTH), $@ - $(DML_FILE_PATH) , $(DEBUG_DEFAULT_HDR_CHAR), $(DEBUG_DEFAULT_HDR_FG))
	@sqlite3 $(SQLITE_DB_FILE) < $(DML_FILE_PATH)

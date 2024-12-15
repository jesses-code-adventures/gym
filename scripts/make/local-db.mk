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

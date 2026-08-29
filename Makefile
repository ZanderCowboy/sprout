APP_DIR := sprout_app

FLAVOR_DEV := development
FLAVOR_PROD := production
TARGET_DEV := lib/main_development.dart
TARGET_PROD := lib/main_production.dart

.PHONY: help get run run-dev run-prod run-dev-release run-prod-release \
	analyze test check clean devices config \
	config-export config-import config-status config-set-onedrive

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

get: ## flutter pub get
	cd $(APP_DIR) && flutter pub get

run: run-dev ## Alias for run-dev

run-dev: ## Run development flavor (debug)
	cd $(APP_DIR) && flutter run --flavor $(FLAVOR_DEV) -t $(TARGET_DEV)

run-prod: ## Run production flavor (debug)
	cd $(APP_DIR) && flutter run --flavor $(FLAVOR_PROD) -t $(TARGET_PROD)

run-dev-release: ## Run development flavor (release)
	cd $(APP_DIR) && flutter run --release --flavor $(FLAVOR_DEV) -t $(TARGET_DEV)

run-prod-release: ## Run production flavor (release)
	cd $(APP_DIR) && flutter run --release --flavor $(FLAVOR_PROD) -t $(TARGET_PROD)

analyze: ## flutter analyze
	cd $(APP_DIR) && flutter analyze

test: ## flutter test
	cd $(APP_DIR) && flutter test

check: analyze test ## Analyze then test (CI-equivalent)

clean: ## flutter clean + pub get
	cd $(APP_DIR) && flutter clean && flutter pub get

devices: ## List connected devices / emulators
	flutter devices

config: ## Create empty local config JSON assets if missing
	@mkdir -p $(APP_DIR)/assets/config
	@for f in development.json production.json; do \
		path="$(APP_DIR)/assets/config/$$f"; \
		if [ ! -f "$$path" ]; then \
			printf '%s\n' '{' \
				'  "supabaseUrl": "",' \
				'  "supabaseAnonKey": ""' \
				'}' > "$$path"; \
			echo "Created $$path"; \
		else \
			echo "Exists  $$path"; \
		fi; \
	done

# Optional: ONEDRIVE=C:/Users/you/OneDrive  or  DEST=/full/path/to/sprout-local-config
config-export: ## Copy gitignored local config to OneDrive (ONEDRIVE= or DEST=)
	@if [ -n "$(DEST)" ]; then \
		scripts/sync-local-config.sh export --dest "$(DEST)"; \
	elif [ -n "$(ONEDRIVE)" ]; then \
		scripts/sync-local-config.sh export --onedrive "$(ONEDRIVE)"; \
	else \
		scripts/sync-local-config.sh export; \
	fi

config-import: ## Restore gitignored local config from OneDrive (ONEDRIVE= or DEST=)
	@if [ -n "$(DEST)" ]; then \
		scripts/sync-local-config.sh import --dest "$(DEST)"; \
	elif [ -n "$(ONEDRIVE)" ]; then \
		scripts/sync-local-config.sh import --onedrive "$(ONEDRIVE)"; \
	else \
		scripts/sync-local-config.sh import; \
	fi

config-status: ## Show which local-config files exist here vs OneDrive
	@if [ -n "$(DEST)" ]; then \
		scripts/sync-local-config.sh status --dest "$(DEST)"; \
	elif [ -n "$(ONEDRIVE)" ]; then \
		scripts/sync-local-config.sh status --onedrive "$(ONEDRIVE)"; \
	else \
		scripts/sync-local-config.sh status; \
	fi

config-set-onedrive: ## Save OneDrive root to gitignored .sprout-onedrive (ONEDRIVE= required)
	@if [ -z "$(ONEDRIVE)" ]; then \
		echo 'Usage: make config-set-onedrive ONEDRIVE="C:/Users/you/OneDrive"'; \
		exit 1; \
	fi
	@scripts/sync-local-config.sh set-onedrive "$(ONEDRIVE)"

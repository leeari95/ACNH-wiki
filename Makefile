# ============================================================================
# Makefile — ACNH-wiki (Animal Crossing: New Horizons Guide iOS App)
# ============================================================================
#
# Convenience targets for building, linting, validating, and running CI checks.
#
# Prerequisites:
#   - mise (https://mise.jdx.dev/) for Tuist version management
#   - SwiftLint installed and available on PATH
#
# Usage:
#   make          — Show available targets
#   make setup    — One-time project bootstrap
#   make ci       — Full CI pipeline (lint + validate + build)
#
# ============================================================================

.DEFAULT_GOAL := help

.PHONY: setup build lint lint-fix validate-arch validate-patterns validate-docs validate ci hooks help

# ----------------------------------------------------------------------------
# Setup
# ----------------------------------------------------------------------------

setup: ## Full project setup: mise install + tuist install + tuist generate + hooks
	mise install
	mise x -- tuist install
	mise x -- tuist generate --no-open
	$(MAKE) hooks

hooks: ## Configure git to use .githooks/ directory
	git config core.hooksPath .githooks

# ----------------------------------------------------------------------------
# Build
# ----------------------------------------------------------------------------

build: ## Build the project with Tuist
	mise x -- tuist build

# ----------------------------------------------------------------------------
# Lint
# ----------------------------------------------------------------------------

lint: ## Run SwiftLint
	swiftlint --config .swiftlint.yml

lint-fix: ## Run SwiftLint with auto-fix
	swiftlint --config .swiftlint.yml --fix

# ----------------------------------------------------------------------------
# Validation
# ----------------------------------------------------------------------------

validate-arch: ## Run architecture boundary validation
	bash scripts/validate-architecture.sh

validate-patterns: ## Run pattern convention validation
	bash scripts/validate-patterns.sh

validate-docs: ## Run documentation reference validation
	bash scripts/validate-docs.sh

validate: validate-arch validate-patterns validate-docs ## Run all validations (architecture + patterns + docs)

# ----------------------------------------------------------------------------
# CI
# ----------------------------------------------------------------------------

ci: lint validate build ## Full CI check: lint + validate + build

# ----------------------------------------------------------------------------
# Help
# ----------------------------------------------------------------------------

help: ## Show this help message
	@echo ""
	@echo "ACNH-wiki — Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

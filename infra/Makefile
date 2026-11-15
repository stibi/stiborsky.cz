# Shortcuts for running Terraform here, locally. Credentials come from infra/.envrc
# (direnv; see README.md, "Run locally"). Plans only: merging the pull request applies,
# so there is no apply target.
#
#   make plan
#   make target-plan TARGET='cloudflare_dns_record.www'

# Local plans don't take the state lock, so they never block the workflow's apply.
TF := terraform
PLAN_ARGS := -lock=false

# Space-separated resource addresses, e.g. make target-plan TARGET='github_repository.site'
TARGET ?=
TARGET_ARGS := $(foreach t,$(TARGET),-target='$(t)')

.PHONY: help init plan plan-file target-plan ids check fmt check-target

help: ## Show the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-12s %s\n", $$1, $$2}'

init: ## terraform init with the R2 state backend
	$(TF) init

plan: ## Plan against the real state (read-only, no lock)
	$(TF) plan $(PLAN_ARGS)

plan-file: ## Uncoloured plan into a new temp file, summary on screen; honours TARGET
	@f=$$(mktemp "$${TMPDIR:-/tmp}/tf-plan.XXXXXX") && echo "Writing plan to $$f..." && \
	$(TF) plan -no-color $(PLAN_ARGS) $(TARGET_ARGS) >"$$f" 2>&1; rc=$$?; \
	grep -E '^(Plan:|No changes|Error:)' "$$f"; echo "Plan saved to $$f"; exit $$rc

target-plan: check-target ## Plan only TARGET (space-separated addresses)
	$(TF) plan $(PLAN_ARGS) $(TARGET_ARGS)

ids: ## Print the import IDs and what was set by hand in Cloudflare (read-only)
	scripts/discover-ids.sh

check: ## fmt -check and validate, without credentials or state (as in CI)
	scripts/check.sh

fmt: ## Format the Terraform files
	$(TF) fmt -recursive

check-target:
	@test -n "$(strip $(TARGET))" || { echo "TARGET is required, e.g. make $(MAKECMDGOALS) TARGET='cloudflare_dns_record.www'" >&2; exit 1; }

#!/usr/bin/env bash
# The infra check: formatting and validation, without credentials or state.
# Runs in CI, the pre-commit hook and the Stop hook for changes in infra/.
set -euo pipefail
cd "$(dirname "$0")/.."

terraform fmt -check -recursive -diff
# Its own data directory: a local `make init` configures .terraform/ for the R2 backend,
# and validate would then try to read the state, without credentials in a hook or in CI.
export TF_DATA_DIR=.terraform-check
# -backend=false: validation needs the providers, not the state. -lockfile=readonly fails
# if the providers don't match .terraform.lock.hcl instead of quietly rewriting it.
terraform init -backend=false -lockfile=readonly -input=false >/dev/null
terraform validate
bash -n scripts/discover-ids.sh

#!/usr/bin/env bash
# AWS Multi-Account Security and Governance Baseline
# Template script – driven by env/.env
# Usage: bash scripts/aws-cli-setup-commands.sh

set -euo pipefail

# ------------------------------------------------------------------------------
# 0) Load configuration from env/.env
# ------------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${REPO_ROOT}/env/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}"
  echo "Create it first: cp env/.env.example env/.env  (then edit values)"
  exit 1
fi

# shellcheck source=/dev/null
source "${ENV_FILE}"

# Expected variables (must exist in env/.env):
#   ACCOUNT_ALIAS           # the single alias you intend to set in THIS account (string; required)
#   PRIMARY_ALIAS           # example: 'primary-account' (placeholder; must be changed)
#   SANDBOX_ALIAS           # example: 'sandbox-account' (placeholder; must be changed)
#   ADMIN_USER              # example: 'AdminUser' (placeholder; must be changed)
#   READONLY_USER           # example: 'ReadOnlyUser' (placeholder; must be changed)
#   TEMP_ADMIN_PASSWORD     # example: 'ChangeMe#2025!' (placeholder; must be changed)
#   TEMP_RO_PASSWORD        # example: 'ChangeMe#2025!' (placeholder; must be changed)
#   AWS_DEFAULT_REGION      # e.g., 'us-east-1' (informational)

# ------------------------------------------------------------------------------
# 1) Guards: refuse to run with obvious placeholders or empty required values
# ------------------------------------------------------------------------------
fail=0

# Required non-empty
[[ -z "${ACCOUNT_ALIAS:-}"      ]] && echo "ACCOUNT_ALIAS is empty in env/.env" && fail=1
[[ -z "${ADMIN_USER:-}"         ]] && echo "ADMIN_USER is empty in env/.env" && fail=1
[[ -z "${READONLY_USER:-}"      ]] && echo "READONLY_USER is empty in env/.env" && fail=1
[[ -z "${TEMP_ADMIN_PASSWORD:-}" ]] && echo "TEMP_ADMIN_PASSWORD is empty in env/.env" && fail=1
[[ -z "${TEMP_RO_PASSWORD:-}"    ]] && echo "TEMP_RO_PASSWORD is empty in env/.env" && fail=1

# Obvious placeholders – require the user to change them
[[ "${ACCOUNT_ALIAS}"         == "primary-account"  ]] && echo "Change ACCOUNT_ALIAS from 'primary-account' to your real alias." && fail=1
[[ "${ACCOUNT_ALIAS}"         == "sandbox-account"   ]] && echo "Change ACCOUNT_ALIAS from 'sandbox-account' to your real alias." && fail=1
[[ "${PRIMARY_ALIAS:-}"       == "primary-account"   ]] && echo "Change PRIMARY_ALIAS placeholder value." && fail=1
[[ "${SANDBOX_ALIAS:-}"       == "sandbox-account"   ]] && echo "Change SANDBOX_ALIAS placeholder value." && fail=1
[[ "${ADMIN_USER}"            == "AdminUser"         ]] && echo "Change ADMIN_USER placeholder value." && fail=1
[[ "${READONLY_USER}"         == "ReadOnlyUser"      ]] && echo "Change READONLY_USER placeholder value." && fail=1
[[ "${TEMP_ADMIN_PASSWORD}"   == "ChangeMe#2025!"    ]] && echo "Change TEMP_ADMIN_PASSWORD placeholder value." && fail=1
[[ "${TEMP_RO_PASSWORD}"      == "ChangeMe#2025!"    ]] && echo "Change TEMP_RO_PASSWORD placeholder value." && fail=1

if (( fail )); then
  echo "Refusing to run due to placeholders or empty required values in env/.env."
  exit 1
fi

# ------------------------------------------------------------------------------
# 2) Preconditions
# ------------------------------------------------------------------------------
if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI not found in PATH. Install AWS CLI v2 and run 'aws configure'."
  exit 1
fi

echo "Verifying AWS caller identity..."
aws sts get-caller-identity

echo "AWS account aliases (current):"
aws iam list-account-aliases || true

# ------------------------------------------------------------------------------
# 3) Helpers (idempotent)
# ------------------------------------------------------------------------------
create_or_verify_alias() {
  local alias="$1"
  echo "Ensuring account alias '${alias}' exists..."

  local count
  count="$(aws iam list-account-aliases --query "length(AccountAliases[?@=='${alias}'])" --output text || echo "0")"

  if [[ "${count}" == "1" ]]; then
    echo "Alias '${alias}' already present."
    return 0
  fi

  # Try to create; if an alias already exists (different name), user must change it manually.
  set +e
  aws iam create-account-alias --account-alias "${alias}"
  rc=$?
  set -e

  if (( rc != 0 )); then
    echo "Could not create alias '${alias}'. Likely another alias exists on this account."
    echo "Resolve by deleting the existing alias, then creating the new one:"
    echo "  aws iam list-account-aliases"
    echo "  aws iam delete-account-alias --account-alias <existing>"
    echo "  aws iam create-account-alias --account-alias ${alias}"
    exit 1
  fi

  echo "Alias '${alias}' created."
}

user_exists() {
  local user="$1"
  aws iam get-user --user-name "${user}" >/dev/null 2>&1
}

create_user_if_missing() {
  local user="$1"
  if user_exists "${user}"; then
    echo "User '${user}' exists."
  else
    echo "Creating IAM user '${user}'..."
    aws iam create-user --user-name "${user}"
  fi
}

ensure_login_profile() {
  local user="$1" pw="$2"
  if aws iam get-login-profile --user-name "${user}" >/dev/null 2>&1; then
    echo "Updating console password for '${user}' (no reset required)..."
    aws iam update-login-profile --user-name "${user}" --password "${pw}" --no-password-reset-required
  else
    echo "Creating console login profile for '${user}' (password reset required on first login)..."
    aws iam create-login-profile --user-name "${user}" --password "${pw}" --password-reset-required
  fi
}

attach_policy_if_missing() {
  local user="$1" policy_arn="$2"
  local present
  present="$(aws iam list-attached-user-policies --user-name "${user}" \
              --query "length(AttachedPolicies[?PolicyArn=='${policy_arn}'])" \
              --output text || echo "0")"
  if [[ "${present}" == "1" ]]; then
    echo "Policy already attached to '${user}': ${policy_arn}"
  else
    echo "Attaching policy to '${user}': ${policy_arn}"
    aws iam attach-user-policy --user-name "${user}" --policy-arn "${policy_arn}"
  fi
}

# ------------------------------------------------------------------------------
# 4) Apply configuration
# ------------------------------------------------------------------------------
echo "Setting/confirming account alias: ${ACCOUNT_ALIAS}"
create_or_verify_alias "${ACCOUNT_ALIAS}"

echo "Ensuring administrative user: ${ADMIN_USER}"
create_user_if_missing "${ADMIN_USER}"
ensure_login_profile   "${ADMIN_USER}" "${TEMP_ADMIN_PASSWORD}"
attach_policy_if_missing "${ADMIN_USER}" "arn:aws:iam::aws:policy/AdministratorAccess"

echo "Ensuring read-only user: ${READONLY_USER}"
create_user_if_missing "${READONLY_USER}"
ensure_login_profile   "${READONLY_USER}" "${TEMP_RO_PASSWORD}"
attach_policy_if_missing "${READONLY_USER}" "arn:aws:iam::aws:policy/ReadOnlyAccess"

# ------------------------------------------------------------------------------
# 5) Next steps and verification
# ------------------------------------------------------------------------------
cat <<'NEXT'

Next steps (console actions):
1) Assign MFA:
   - Console → IAM → Users → <ADMIN_USER> → Security credentials → Assign MFA device
   - Console → IAM → Users → <READONLY_USER> → Security credentials → Assign MFA device
   - Root user: My Security Credentials → MFA

2) Verify via CLI:
   aws iam list-mfa-devices --user-name "<ADMIN_USER>"
   aws iam list-mfa-devices --user-name "<READONLY_USER>"

3) Sign-in URL:
   https://<ACCOUNT_ALIAS>.signin.aws.amazon.com/console

NEXT

echo "Completed."

# To execute this script, use the following command in the CLI 
# bash scripts/aws-cli-setup-commands.sh 
#

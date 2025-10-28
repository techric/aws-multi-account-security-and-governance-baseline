#!/usr/bin/env bash
# AWS Multi-Account Security & Governance Baseline
# Helper CLI script (safe-by-default, uses placeholders you must edit)
# Usage:
#   1) Edit the PLACEHOLDER_* values
#   2) Export AWS credentials for the account you're configuring
#   3) Run commands section-by-section

set -euo pipefail

### ────────────────────────────────────────────────────────────────────────────
### EDIT THESE PLACEHOLDERS BEFORE RUNNING
### ────────────────────────────────────────────────────────────────────────────
PRIMARY_ALIAS="primary-account"        # e.g., PrimaryAccount alias
SANDBOX_ALIAS="sandbox-account"        # e.g., SandboxAccount alias
ADMIN_USER="AdminUser"                 # admin IAM username
READONLY_USER="ReadOnlyUser"           # read-only IAM username
TEMP_ADMIN_PASSWORD='ChangeMe#2025!'   # temp console password (rotate after login)
TEMP_RO_PASSWORD='ChangeMe#2025!'      # temp console password (rotate after login)
REGION="us-east-1"                     # set your preferred default region

### ────────────────────────────────────────────────────────────────────────────
### Identity & Sanity Checks
### ────────────────────────────────────────────────────────────────────────────
echo "==> Who am I?"
aws sts get-caller-identity

echo "==> Current account aliases (if any)"
aws iam list-account-aliases

### ────────────────────────────────────────────────────────────────────────────
### Create/Update Account Alias (run per account)
### ────────────────────────────────────────────────────────────────────────────
# NOTE: 'create-account-alias' fails if alias exists; use 'delete' then 'create' to change.
# Uncomment ONE of these blocks per account session.

# echo "==> Setting account alias to PRIMARY_ALIAS (${PRIMARY_ALIAS})"
# aws iam create-account-alias --account-alias "${PRIMARY_ALIAS}"

# echo "==> Setting account alias to SANDBOX_ALIAS (${SANDBOX_ALIAS})"
# aws iam create-account-alias --account-alias "${SANDBOX_ALIAS}"

### ────────────────────────────────────────────────────────────────────────────
### Create IAM Users (Admin + ReadOnly) with console access
### ────────────────────────────────────────────────────────────────────────────
# Admin user
if ! aws iam get-user --user-name "${ADMIN_USER}" >/dev/null 2>&1; then
  echo "==> Creating IAM user: ${ADMIN_USER}"
  aws iam create-user --user-name "${ADMIN_USER}"
fi

# Read-only user
if ! aws iam get-user --user-name "${READONLY_USER}" >/dev/null 2>&1; then
  echo "==> Creating IAM user: ${READONLY_USER}"
  aws iam create-user --user-name "${READONLY_USER}"
fi

# Grant console passwords (login profiles). If profile exists, update instead.
echo "==> Granting console access (login profiles)"
if aws iam get-login-profile --user-name "${ADMIN_USER}" >/dev/null 2>&1; then
  aws iam update-login-profile --user-name "${ADMIN_USER}" --password "${TEMP_ADMIN_PASSWORD}" --no-password-reset-required
else
  aws iam create-login-profile --user-name "${ADMIN_USER}" --password "${TEMP_ADMIN_PASSWORD}" --password-reset-required
fi

if aws iam get-login-profile --user-name "${READONLY_USER}" >/dev/null 2>&1; then
  aws iam update-login-profile --user-name "${READONLY_USER}" --password "${TEMP_RO_PASSWORD}" --no-password-reset-required
else
  aws iam create-login-profile --user-name "${READONLY_USER}" --password "${TEMP_RO_PASSWORD}" --password-reset-required
fi

### ────────────────────────────────────────────────────────────────────────────
### Attach Policies (least-privilege for ReadOnlyUser)
### ────────────────────────────────────────────────────────────────────────────
echo "==> Attaching AdministratorAccess to ${ADMIN_USER}"
aws iam attach-user-policy --user-name "${ADMIN_USER}" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

echo "==> Attaching ReadOnlyAccess to ${READONLY_USER}"
aws iam attach-user-policy --user-name "${READONLY_USER}" --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

### ────────────────────────────────────────────────────────────────────────────
### MFA (manual step via Console)
### ────────────────────────────────────────────────────────────────────────────
cat <<'NOTE'

[MFA SETUP – MANUAL VIA CONSOLE]
1) Sign in to the Console with each user, then go to:
   IAM → Users → <User> → Security credentials → Assign MFA device → Virtual MFA
2) Scan QR with your authenticator (e.g., Proton Authenticator), enter two codes, save.
3) (Optional) Verify via CLI:
   aws iam list-mfa-devices --user-name "<User>"

NOTE

### ────────────────────────────────────────────────────────────────────────────
### Validation
### ────────────────────────────────────────────────────────────────────────────
echo "==> Users:"
aws iam list-users

echo "==> Policies attached to ${ADMIN_USER}:"
aws iam list-attached-user-policies --user-name "${ADMIN_USER}"

echo "==> Policies attached to ${READONLY_USER}:"
aws iam list-attached-user-policies --user-name "${READONLY_USER}"

echo "==> Done. Rotate the temporary console passwords after first login."

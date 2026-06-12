#!/usr/bin/env bash
# =============================================================================
# generate-secrets.sh
# -----------------------------------------------------------------------------
# Creates .env from .env.example and fills in cryptographically random secrets.
# Idempotent-safe: refuses to overwrite an existing .env unless --force.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
TEMPLATE="${SCRIPT_DIR}/.env.example"

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

if [[ ! -f "${TEMPLATE}" ]]; then
    echo "ERROR: ${TEMPLATE} not found." >&2
    exit 1
fi

if [[ -f "${ENV_FILE}" && "${FORCE}" -eq 0 ]]; then
    echo "ERROR: ${ENV_FILE} already exists. Re-run with --force to overwrite." >&2
    exit 1
fi

command -v openssl >/dev/null 2>&1 || {
    echo "ERROR: openssl is required but not installed." >&2
    exit 1
}

PG_PASSWORD="$(openssl rand -base64 24)"
ENCRYPTION_KEY="$(openssl rand -hex 32)"

cp "${TEMPLATE}" "${ENV_FILE}"

# Portable in-place edit (works on both GNU and BSD sed).
sed -i.bak "s|CHANGE_ME_postgres_password|${PG_PASSWORD}|" "${ENV_FILE}"
sed -i.bak "s|CHANGE_ME_32_byte_hex_key|${ENCRYPTION_KEY}|" "${ENV_FILE}"
rm -f "${ENV_FILE}.bak"

chmod 600 "${ENV_FILE}"

echo "Generated ${ENV_FILE} with random secrets (permissions: 600)."
echo "Review it, then run: docker compose up -d"

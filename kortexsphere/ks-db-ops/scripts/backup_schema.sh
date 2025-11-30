#!/usr/bin/env bash
set -euo pipefail

DB_NAME="ks_dev"
DB_USER="backup_user"

BACKUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/backups"
SCHEMA_DIR="$BACKUP_ROOT/schema"

mkdir -p "$SCHEMA_DIR"

TS="$(date +"%Y-%m-%d_%H-%M-%S")"
FILE="$SCHEMA_DIR/${DB_NAME}_schema_${TS}.sql"

echo "Creating schema backup: $FILE"
PGPASSWORD="admin" pg_dump -U "$DB_USER" -s -d "$DB_NAME" > "$FILE"

echo "Done."

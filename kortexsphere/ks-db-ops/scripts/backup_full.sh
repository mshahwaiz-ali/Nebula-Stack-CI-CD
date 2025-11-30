#!/usr/bin/env bash
set -euo pipefail

DB_NAME="ks_dev"
DB_USER="backup_user"

BACKUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/backups"
FULL_DIR="$BACKUP_ROOT/full"

mkdir -p "$FULL_DIR"

TS="$(date +"%Y-%m-%d_%H-%M-%S")"
FILE="$FULL_DIR/${DB_NAME}_full_${TS}.sql"

echo "Creating full backup: $FILE"
PGPASSWORD="admin" pg_dump -U "$DB_USER" -C -d "$DB_NAME" > "$FILE"

echo "Done."

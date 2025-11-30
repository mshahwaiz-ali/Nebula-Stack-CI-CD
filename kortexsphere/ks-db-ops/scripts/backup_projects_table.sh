#!/usr/bin/env bash
set -euo pipefail

DB_NAME="ks_dev"
DB_USER="backup_user"
TABLE_NAME="projects"

BACKUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/backups"
TABLE_DIR="$BACKUP_ROOT/tables"

mkdir -p "$TABLE_DIR"

TS="$(date +"%Y-%m-%d_%H-%M-%S")"
FILE="$TABLE_DIR/${DB_NAME}_${TABLE_NAME}_${TS}.sql"

echo "Creating table backup: $FILE"
PGPASSWORD="admin" pg_dump -U "$DB_USER" -t "$TABLE_NAME" -d "$DB_NAME" > "$FILE"

echo "Done."

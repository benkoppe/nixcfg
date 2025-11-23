#!/usr/bin/env bash
set -euo pipefail
shopt -s extglob

# Check backup folder exists
if [ ! -d "$BACKUP_FOLDER" ]; then
  echo "Backup folder '$BACKUP_FOLDER' does not exist" >&2
  exit 1
fi

# If data folder doesn't yet exist (first startup), exit gracefully
if [ ! -d "$DATA_FOLDER" ]; then
  echo "No data folder yet; skipping backup."
  exit 0
fi

# Perform SQLite backup if present
if [ -f "$DATA_FOLDER/db.sqlite3" ]; then
  sqlite3 "$DATA_FOLDER/db.sqlite3" ".backup '$BACKUP_FOLDER/db.sqlite3'"
fi

# Copy all non-db.* files/dirs if they exist
shopt -s nullglob
files=("$DATA_FOLDER"/!(db.*))
shopt -u nullglob

if ((${#files[@]})); then
  cp -r "${files[@]}" "$BACKUP_FOLDER"/
fi

echo "Backup complete."

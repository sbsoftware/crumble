#!/usr/bin/env sh

SCRIPT_DIR=$(dirname "$0")

if [ -f "$SCRIPT_DIR/.env" ]; then
  # Export sourced assignments so the delegated watcher inherits them.
  set -a
  . "$SCRIPT_DIR/.env"
  set +a
fi

cd "$SCRIPT_DIR" || exit 1
exec "$SCRIPT_DIR/lib/crumble/src/watch.sh" "__CRUMBLE_NAME__" "__CRUMBLE_PORT__"

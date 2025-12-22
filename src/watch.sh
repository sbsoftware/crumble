#!/usr/bin/env sh

PROJ_FILENAME=$1
PORT=$2
SRC_FILENAME="src/$PROJ_FILENAME.cr"
BIN_FILENAME="bin/$PROJ_FILENAME"

watchexec -r -w src -w lib -e cr --no-vcs-ignore "crystal build --error-trace $SRC_FILENAME -o $BIN_FILENAME" &
COMPILE_PID=$!

export DATABASE_URL="${DATABASE_URL:-sqlite3://./data.db}"
export ORMA_CONTINUOUS_MIGRATION="${ORMA_CONTINUOUS_MIGRATION:-1}"
export LOG_LEVEL="${LOG_LEVEL:-trace}"

watchexec -r -w "./bin" -f $PROJ_FILENAME --fs-events metadata --no-vcs-ignore "$BIN_FILENAME -p $PORT" &
RUN_PID=$!

cleanup() {
  echo "Stopping child processes..."
  kill "$COMPILE_PID" "$RUN_PID" 2> /dev/null
  wait "$COMPILE_PID" "$RUN_PID" 2> /dev/null
  exit
}

trap cleanup SIGINT SIGTERM

echo "Press Ctrl+C to stop"

wait

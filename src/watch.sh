#!/usr/bin/env sh

if [ "$1" = "--docker-container" ]; then
  SRC_FILENAME=$2
  PORT=$3

  if command -v watchexec > /dev/null 2>&1; then
    exec watchexec -r --poll 1000 -w src -w lib -e cr -- sh -c 'crystal run --error-trace "$1" -- -p "$2"' sh "$SRC_FILENAME" "$PORT"
  fi

  echo "watchexec missing in image; running without restart-on-change. Install watchexec in the development image to enable automatic restarts." >&2
  exec crystal run --error-trace "$SRC_FILENAME" -- -p "$PORT"
fi

PROJ_FILENAME=$1
PORT=$2
SRC_FILENAME="src/$PROJ_FILENAME.cr"
BIN_FILENAME="bin/$PROJ_FILENAME"
WATCH_SCRIPT=${0#"$PWD"/}

export DATABASE_URL="${DATABASE_URL:-sqlite3://./data.db}"
export ORMA_CONTINUOUS_MIGRATION="${ORMA_CONTINUOUS_MIGRATION:-1}"
export LOG_LEVEL="${LOG_LEVEL:-trace}"

if [ -f "Dockerfile" ] && command -v docker > /dev/null 2>&1 && docker info > /dev/null 2>&1; then
  IMAGE_NAME="$PROJ_FILENAME-development"
  CONTAINER_NAME="$PROJ_FILENAME-development"
  PUBLISH_PORT=""
  if [ "$PORT" != "0" ]; then
    PUBLISH_PORT="-p '$PORT:$PORT'"
  fi

  cleanup() {
    echo "Stopping child processes..."
    kill "$WATCH_PID" 2> /dev/null
    wait "$WATCH_PID" 2> /dev/null
    docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1
    exit
  }

  trap cleanup SIGINT SIGTERM

  # Event variables are empty for the initial run, while later events identify
  # whether the image definition changed or only the container environment did.
  watchexec -r -w Dockerfile -w .env --emit-events-to=environment --no-vcs-ignore "EVENT_PATHS=\"\$WATCHEXEC_COMMON_PATH:\$WATCHEXEC_CREATED_PATH:\$WATCHEXEC_WRITTEN_PATH:\$WATCHEXEC_REMOVED_PATH:\$WATCHEXEC_RENAMED_PATH\"; if [ \"\$EVENT_PATHS\" = '::::' ] || printf '%s\\n' \"\$EVENT_PATHS\" | grep -q 'Dockerfile'; then docker build -t '$IMAGE_NAME' . || exit; fi; if [ -f .env ]; then set -a; . ./.env; set +a; fi; (docker rm -f '$CONTAINER_NAME' > /dev/null 2>&1 || true) && docker run --rm --name '$CONTAINER_NAME' -e DATABASE_URL -e ORMA_CONTINUOUS_MIGRATION -e LOG_LEVEL -v '$PWD:/workspace' -w /workspace $PUBLISH_PORT '$IMAGE_NAME' sh '$WATCH_SCRIPT' --docker-container '$SRC_FILENAME' '$PORT'" &
  WATCH_PID=$!

  echo "Press Ctrl+C to stop"

  wait "$WATCH_PID"
  exit
fi

watchexec -r -w src -w lib -e cr --no-vcs-ignore "crystal build --error-trace $SRC_FILENAME -o $BIN_FILENAME" &
COMPILE_PID=$!

# The bin watcher starts before the first compile completes, so skip the initial
# run until the compiler has produced a binary to execute.
watchexec -r -w "./bin" -f $PROJ_FILENAME --no-vcs-ignore "if [ -f \"$BIN_FILENAME\" ]; then \"$BIN_FILENAME\" -p \"$PORT\"; fi" &
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

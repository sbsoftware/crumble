#!/usr/bin/env sh

PROJ_FILENAME=$1
PORT=$2
SRC_FILENAME="src/$PROJ_FILENAME.cr"
BIN_FILENAME="bin/$PROJ_FILENAME"

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

  # Removing the previous container before each run also cleans up containers
  # left behind when watchexec stops the foreground Docker client on a rebuild.
  watchexec -r -w src -w lib -w shard.yml -w shard.lock -w Dockerfile --no-vcs-ignore "docker build -t '$IMAGE_NAME' . && (docker rm -f '$CONTAINER_NAME' > /dev/null 2>&1 || true) && docker run --rm --name '$CONTAINER_NAME' -e DATABASE_URL -e ORMA_CONTINUOUS_MIGRATION -e LOG_LEVEL $PUBLISH_PORT '$IMAGE_NAME' -p '$PORT'" &
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

#!/bin/sh
# render-start.sh - Start both App and Runtime servers

set -e

echo "Starting SmythOS Studio on Render..."

# Export PORT for Render compatibility (maps to APP_PORT)
export APP_PORT=${PORT:-5050}
export RUNTIME_PORT=${RUNTIME_PORT:-5053}

echo "App will run on port: $APP_PORT"
echo "Runtime will run on port: $RUNTIME_PORT"

# Start the Runtime server in background
echo "Starting Runtime server..."
cd /app/packages/runtime
PORT=$RUNTIME_PORT NODE_ENV=production node dist/index.js &
RUNTIME_PID=$!

# Wait a moment for runtime to initialize
sleep 2

# Start the App server in foreground (keeps container alive)
echo "Starting App server..."
cd /app/packages/app
PORT=$APP_PORT NODE_ENV=production node dist/server/index.js &
APP_PID=$!

# Handle shutdown gracefully
trap 'echo "Shutting down..."; kill $RUNTIME_PID $APP_PID 2>/dev/null; exit 0' SIGTERM SIGINT

# Wait for both processes
wait
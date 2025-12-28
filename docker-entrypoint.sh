#!/bin/sh
set -e

echo "CHATWOOT_MODE: $CHATWOOT_MODE"
echo "PORT: $PORT"

if [ "$CHATWOOT_MODE" = "worker" ]; then
  echo "Starting Sidekiq worker with health check server..."
  
  # Start a minimal health check server in the background using Ruby
  # This is more reliable than netcat and Ruby is already available
  ruby -run -e httpd /dev/null -p "$PORT" &
  HEALTH_PID=$!
  echo "Health check server started on port $PORT (PID: $HEALTH_PID)"
  
  # Give the health server a moment to start
  sleep 2
  
  # Start Sidekiq as the main process
  exec bundle exec sidekiq -C config/sidekiq.yml
else
  echo "Starting Rails server..."
  exec bundle exec rails s -p "$PORT" -b 0.0.0.0
fi

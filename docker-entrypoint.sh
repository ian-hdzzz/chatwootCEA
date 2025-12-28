#!/bin/sh
set -e

echo "CHATWOOT_MODE: $CHATWOOT_MODE"
echo "PORT: $PORT"

if [ "$CHATWOOT_MODE" = "worker" ]; then
  echo "Starting Sidekiq worker with health check server..."
  
  # Start a minimal health check server in the background
  # This responds to Cloud Run health checks on the configured PORT
  while true; do
    echo -e "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK" | nc -l -p "$PORT" -q 1 2>/dev/null || true
  done &
  
  # Start Sidekiq as the main process
  exec bundle exec sidekiq -C config/sidekiq.yml
else
  echo "Starting Rails server..."
  exec bundle exec rails s -p "$PORT" -b 0.0.0.0
fi

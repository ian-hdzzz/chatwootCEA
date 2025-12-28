FROM chatwoot/chatwoot:latest

WORKDIR /app

# Install netcat for health check server (if not already available)
USER root
RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*
USER chatwoot

# Copia solo archivos necesarios (respetando .dockerignore)
COPY . /app

# Copy and set permissions for entrypoint script
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
USER root
RUN chmod +x /app/docker-entrypoint.sh
USER chatwoot

# Usa la variable PORT de Cloud Run (por defecto 8080)
ENV PORT=8080
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true

# Mode selector: "web" (default) or "worker"
ENV CHATWOOT_MODE=web

EXPOSE 8080

# Use entrypoint script
ENTRYPOINT ["/app/docker-entrypoint.sh"]
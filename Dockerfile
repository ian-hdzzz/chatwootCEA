FROM chatwoot/chatwoot:latest

WORKDIR /app

# Copia solo archivos necesarios (respetando .dockerignore)
COPY . /app

# Usa la variable PORT de Cloud Run (por defecto 8080)
ENV PORT=8080
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true

EXPOSE 8080

# Script de inicio con mejor manejo de errores y logs
CMD ["sh", "-c", "echo 'Starting Chatwoot...' && echo 'Checking environment...' && env | grep -E '(POSTGRES|REDIS|RAILS|PORT)' && echo 'Running migrations...' && bundle exec rails db:chatwoot_prepare && echo 'Starting Rails server on port $PORT...' && bundle exec rails s -p ${PORT} -b 0.0.0.0"]
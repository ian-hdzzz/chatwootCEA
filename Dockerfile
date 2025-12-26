FROM chatwoot/chatwoot:latest

WORKDIR /app

# Copia solo archivos necesarios (respetando .dockerignore)
COPY . /app

# Usa la variable PORT de Cloud Run (por defecto 8081)
ENV PORT=8081
EXPOSE 8081

# Script de inicio que ejecuta migraciones y arranca el servidor
CMD ["sh", "-c", "bundle exec rails db:chatwoot_prepare && bundle exec rails s -p ${PORT} -b 0.0.0.0"]
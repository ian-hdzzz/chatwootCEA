FROM chatwoot/chatwoot:latest

WORKDIR /app

# Copia solo archivos necesarios (respetando .dockerignore)
COPY . /app

EXPOSE 3000

# Usa el comando por defecto de la imagen base
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
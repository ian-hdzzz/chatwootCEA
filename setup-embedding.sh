#!/bin/bash

# Script para configurar Chatwoot para embedding
# Uso: ./setup-embedding.sh [dominio1] [dominio2] ...

echo "🔧 Configurando Chatwoot para permitir embedding..."
echo ""

# Detectar si existe archivo .env
if [ ! -f .env ]; then
    echo "📝 No existe archivo .env, creando desde .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "✅ Archivo .env creado"
    else
        echo "❌ No existe .env.example"
        exit 1
    fi
fi

# Si se proporcionan argumentos, usarlos como dominios
if [ $# -gt 0 ]; then
    DOMAINS=$(IFS=, ; echo "$*")
    echo "🌐 Dominios a permitir: $DOMAINS"
    
    # Verificar si ya existe ALLOWED_FRAME_ANCESTORS en .env
    if grep -q "ALLOWED_FRAME_ANCESTORS" .env; then
        # Actualizar valor existente
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|ALLOWED_FRAME_ANCESTORS=.*|ALLOWED_FRAME_ANCESTORS=$DOMAINS|" .env
        else
            # Linux
            sed -i "s|ALLOWED_FRAME_ANCESTORS=.*|ALLOWED_FRAME_ANCESTORS=$DOMAINS|" .env
        fi
        echo "✅ ALLOWED_FRAME_ANCESTORS actualizado en .env"
    else
        # Agregar nueva línea
        echo "ALLOWED_FRAME_ANCESTORS=$DOMAINS" >> .env
        echo "✅ ALLOWED_FRAME_ANCESTORS agregado a .env"
    fi
else
    echo "ℹ️  No se proporcionaron dominios. Configurando para desarrollo local..."
    DOMAINS="http://localhost:5173,http://localhost:3001,http://127.0.0.1:5173"
    
    if grep -q "ALLOWED_FRAME_ANCESTORS" .env; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|ALLOWED_FRAME_ANCESTORS=.*|ALLOWED_FRAME_ANCESTORS=$DOMAINS|" .env
        else
            sed -i "s|ALLOWED_FRAME_ANCESTORS=.*|ALLOWED_FRAME_ANCESTORS=$DOMAINS|" .env
        fi
    else
        echo "ALLOWED_FRAME_ANCESTORS=$DOMAINS" >> .env
    fi
    echo "✅ Configurado para desarrollo: $DOMAINS"
fi

# Habilitar CORS si no está configurado
if ! grep -q "ENABLE_API_CORS" .env; then
    echo "ENABLE_API_CORS=true" >> .env
    echo "✅ ENABLE_API_CORS habilitado"
fi

echo ""
echo "✨ Configuración completada!"
echo ""
echo "📋 Siguiente pasos:"
echo "1. Verifica tu archivo .env"
echo "2. Reinicia Chatwoot:"
echo "   - Docker: docker-compose restart"
echo "   - Rails: bundle exec rails restart"
echo ""
echo "🧪 Para probar, crea un archivo HTML con:"
echo "   <iframe src=\"http://localhost:3000/widget?website_token=TOKEN\"></iframe>"
echo ""

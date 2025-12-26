#!/bin/bash

# Script para configurar variables de entorno en Cloud Run
# Uso: ./setup-cloudrun-secrets.sh

set -e

PROJECT_ID="clever-obelisk-277705"
SERVICE_NAME="chatwootcea"
REGION="us-central1"

echo "🔧 Configurando variables de entorno para Cloud Run..."

# Genera un SECRET_KEY_BASE si no lo tienes
SECRET_KEY_BASE=$(openssl rand -hex 64)
echo "✅ SECRET_KEY_BASE generado"

# Configura las variables de entorno básicas
gcloud run services update $SERVICE_NAME \
  --region=$REGION \
  --project=$PROJECT_ID \
  --update-env-vars="
SECRET_KEY_BASE=$SECRET_KEY_BASE,
RAILS_ENV=production,
RAILS_LOG_TO_STDOUT=true,
PORT=8080,
FORCE_SSL=true,
ENABLE_ACCOUNT_SIGNUP=false,
RAILS_MAX_THREADS=5,
LOG_LEVEL=info
" \
  --no-traffic

echo ""
echo "⚠️  IMPORTANTE: Debes configurar manualmente:"
echo ""
echo "1. FRONTEND_URL - URL de tu servicio Cloud Run"
echo "   gcloud run services update $SERVICE_NAME --region=$REGION --update-env-vars=\"FRONTEND_URL=https://tu-url.run.app\""
echo ""
echo "2. PostgreSQL (Cloud SQL):"
echo "   gcloud run services update $SERVICE_NAME --region=$REGION \\"
echo "     --add-cloudsql-instances=PROYECTO:REGION:INSTANCIA \\"
echo "     --update-env-vars=\"POSTGRES_HOST=/cloudsql/PROYECTO:REGION:INSTANCIA,POSTGRES_USERNAME=postgres,POSTGRES_PASSWORD=xxx,POSTGRES_DATABASE=chatwoot_production\""
echo ""
echo "3. Redis (Memorystore):"
echo "   gcloud run services update $SERVICE_NAME --region=$REGION \\"
echo "     --update-env-vars=\"REDIS_URL=redis://10.x.x.x:6379,REDIS_PASSWORD=xxx\""
echo ""
echo "4. Storage (GCS):"
echo "   gcloud run services update $SERVICE_NAME --region=$REGION \\"
echo "     --update-env-vars=\"ACTIVE_STORAGE_SERVICE=google,GCS_PROJECT=$PROJECT_ID,GCS_BUCKET=tu-bucket\""
echo ""
echo "✅ Configuración básica completada!"
echo "📝 Guarda este SECRET_KEY_BASE en un lugar seguro:"
echo "$SECRET_KEY_BASE"

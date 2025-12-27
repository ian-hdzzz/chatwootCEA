# Configuración de Embedding y CORS en Chatwoot

## 🎯 Objetivo
Permitir que Chatwoot sea embebido en iframes desde tu aplicación local o desplegada.

## 🔐 Configuraciones de Seguridad

### 1. Content Security Policy (CSP) - frame-ancestors

El archivo `config/initializers/content_security_policy.rb` ahora está configurado para:

- ✅ En **desarrollo**: Permite automáticamente `localhost` y `127.0.0.1` en cualquier puerto
- ✅ En **producción**: Usa la variable de entorno `ALLOWED_FRAME_ANCESTORS` para whitelist específico

### 2. X-Frame-Options

El controlador `WidgetsController` ya maneja esto correctamente:
- Si configuras `allowed_domains` en el widget, usa CSP con esos dominios
- Si no hay dominios configurados, elimina la restricción X-Frame-Options

## 🚀 Configuración Paso a Paso

### Para Desarrollo Local

1. **Crea o edita tu archivo `.env`**:

```bash
# En la raíz del proyecto chatwootCEA
cp .env.example .env
```

2. **Agrega estas variables a tu `.env`**:

```env
FRONTEND_URL=http://localhost:3000

# Agrega los dominios desde donde vas a embeber Chatwoot
# Ejemplo: si tu app frontend está en localhost:5173
ALLOWED_FRAME_ANCESTORS=http://localhost:5173,http://localhost:3001,http://127.0.0.1:5173

# Opcional: Habilita CORS para API
ENABLE_API_CORS=true
```

3. **Reinicia Chatwoot**:

```bash
# Si usas Docker
docker-compose restart

# Si usas Rails directo
bundle exec rails restart
```

### Para Producción/Despliegue

1. **Configura las variables de entorno en tu servidor**:

```env
FRONTEND_URL=https://tu-chatwoot.com
ALLOWED_FRAME_ANCESTORS=https://tu-app.com,https://www.tu-app.com
ENABLE_API_CORS=true
```

2. **En Cloud Run (si usas GCP)**:

```bash
gcloud run services update chatwoot \
  --set-env-vars="ALLOWED_FRAME_ANCESTORS=https://tu-app.com,https://www.tu-app.com" \
  --region=us-central1
```

### Opción Alternativa: Configurar en el Widget

En lugar de configurar globalmente, puedes configurar dominios permitidos por widget:

1. Ve al panel de Chatwoot
2. Settings → Inboxes → [Tu Web Widget]
3. En "Configuration" → "Widget Configuration"
4. Busca el campo "Allowed Domains" y agrega:

```
https://tu-app.com, https://www.tu-app.com
```

## 🧪 Testing

### 1. Crear una página de prueba HTML

Crea `test-embed.html`:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Chatwoot Embed Test</title>
</head>
<body>
    <h1>Prueba de Embed de Chatwoot</h1>
    
    <!-- Widget de chat -->
    <script>
      (function(d,t) {
        var BASE_URL="http://localhost:3000"; // Cambia por tu URL de Chatwoot
        var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
        g.src=BASE_URL+"/packs/js/sdk.js";
        g.defer = true;
        g.async = true;
        s.parentNode.insertBefore(g,s);
        g.onload=function(){
          window.chatwootSDK.run({
            websiteToken: 'TU_WEBSITE_TOKEN',
            baseUrl: BASE_URL
          })
        }
      })(document,"script");
    </script>

    <!-- O iframe directo (para testing) -->
    <h2>Iframe Test</h2>
    <iframe 
      src="http://localhost:3000/widget?website_token=TU_WEBSITE_TOKEN"
      style="width: 400px; height: 600px; border: 1px solid #ccc;"
    ></iframe>
</body>
</html>
```

### 2. Servir la página de prueba

```bash
# Opción 1: Python
python3 -m http.server 5173

# Opción 2: Node.js
npx serve .

# Opción 3: PHP
php -S localhost:5173
```

### 3. Abrir en navegador

Visita `http://localhost:5173/test-embed.html`

### 4. Verificar en DevTools

Abre la consola del navegador (F12):
- ❌ Si ves errores de CSP o X-Frame-Options → revisa la configuración
- ✅ Si el widget carga correctamente → ¡Funciona!

## 🔍 Debugging

### Ver errores CSP en la consola

Si ves algo como:

```
Refused to frame 'http://localhost:3000' because it violates the following 
Content Security Policy directive: "frame-ancestors 'self'"
```

**Solución**: Asegúrate que:
1. El dominio está en `ALLOWED_FRAME_ANCESTORS`
2. Reiniciaste el servidor después de cambiar `.env`
3. El dominio incluye el protocolo (`http://` o `https://`)

### Ver configuración actual

```bash
# Ver variables de entorno cargadas
rails runner "puts ENV['ALLOWED_FRAME_ANCESTORS']"

# Ver política CSP actual
rails runner "puts Rails.application.config.content_security_policy_report_only"
```

## 🛡️ Mejores Prácticas de Seguridad

### ❌ NO hagas esto en producción:

```env
ALLOWED_FRAME_ANCESTORS=*  # ¡INSEGURO! Permite cualquier dominio
```

### ✅ SÍ haz esto:

```env
# Lista específica de dominios confiables
ALLOWED_FRAME_ANCESTORS=https://app.tuempresa.com,https://dashboard.tuempresa.com
```

## 📝 Archivos Modificados

- ✏️ `config/initializers/content_security_policy.rb` - Configuración CSP con soporte para whitelisting
- ✏️ `.env.example` - Variables de entorno de ejemplo

## 🔗 Referencias

- [MDN: Content-Security-Policy](https://developer.mozilla.org/es/docs/Web/HTTP/CSP)
- [MDN: X-Frame-Options](https://developer.mozilla.org/es/docs/Web/HTTP/Headers/X-Frame-Options)
- [Chatwoot Widget Docs](https://www.chatwoot.com/docs/product/channels/live-chat/sdk/setup)

## 💡 Tips Adicionales

### Para ticket-ace-portal

Si quieres embeber Chatwoot en tu portal `ticket-ace-portal-10225`:

1. Asegúrate que la URL del frontend esté en `ALLOWED_FRAME_ANCESTORS`
2. Si usas Next.js, verifica que no tengas CSP en `next.config.js` bloqueando iframes
3. Si usas Docker Compose, agrega las variables en el `docker-compose.yml`

### Verificar CORS

Si además necesitas hacer llamadas API desde tu frontend:

```javascript
// Ejemplo de llamada API desde tu frontend
fetch('http://localhost:3000/api/v1/accounts/1/contacts', {
  headers: {
    'api_access_token': 'TU_API_TOKEN'
  }
})
```

Asegúrate que `ENABLE_API_CORS=true` esté configurado.

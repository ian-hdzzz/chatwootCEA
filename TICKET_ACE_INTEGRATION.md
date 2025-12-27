# Integración de Chatwoot con Ticket Ace Portal

## 🎯 Objetivo
Integrar el widget de Chatwoot en el portal Ticket Ace para soporte en tiempo real.

## 🔧 Configuración de Chatwoot

### 1. Variables de Entorno

Agrega estas variables a tu `.env` en chatwootCEA:

```env
# URL base de Chatwoot
FRONTEND_URL=http://localhost:3000  # En desarrollo
# FRONTEND_URL=https://chatwoot.tudominio.com  # En producción

# Dominios permitidos para embedding
# Agrega la URL de tu Ticket Ace Portal
ALLOWED_FRAME_ANCESTORS=http://localhost:5173,http://localhost:3001,https://ticket-ace-portal.tudominio.com

# Habilitar CORS para API
ENABLE_API_CORS=true
```

### 2. Reiniciar Chatwoot

```bash
# Si usas Docker
cd /Users/ian.hdzzz/Desktop/chatwootCEA
docker-compose restart

# Si usas Rails directo
bundle exec rails restart
```

## 🚀 Integración en Ticket Ace Portal

### Opción 1: Widget Flotante (Recomendado)

Agrega esto en el `<head>` de tu aplicación o en un layout principal:

#### Para Next.js (Frontend)

Crea el archivo `components/ChatwootWidget.tsx`:

```typescript
'use client';

import { useEffect } from 'react';

interface ChatwootSettings {
  hideMessageBubble?: boolean;
  position?: 'left' | 'right';
  locale?: string;
  type?: 'standard' | 'expanded_bubble';
}

interface ChatwootWidgetProps {
  websiteToken: string;
  baseUrl?: string;
  settings?: ChatwootSettings;
}

export default function ChatwootWidget({
  websiteToken,
  baseUrl = 'http://localhost:3000',
  settings = {}
}: ChatwootWidgetProps) {
  useEffect(() => {
    // Configuración del widget
    (window as any).chatwootSettings = {
      hideMessageBubble: settings.hideMessageBubble || false,
      position: settings.position || 'right',
      locale: settings.locale || 'es',
      type: settings.type || 'standard',
    };

    // Cargar SDK
    (function(d, t) {
      const BASE_URL = baseUrl;
      const g = d.createElement(t) as HTMLScriptElement;
      const s = d.getElementsByTagName(t)[0];
      
      g.src = BASE_URL + "/packs/js/sdk.js";
      g.defer = true;
      g.async = true;
      
      s.parentNode?.insertBefore(g, s);
      
      g.onload = function() {
        (window as any).chatwootSDK?.run({
          websiteToken: websiteToken,
          baseUrl: BASE_URL
        });
      };
    })(document, "script");

    // Cleanup
    return () => {
      if ((window as any).$chatwoot) {
        (window as any).$chatwoot.reset();
      }
    };
  }, [websiteToken, baseUrl, settings]);

  return null;
}
```

Luego úsalo en tu `app/layout.tsx`:

```typescript
import ChatwootWidget from '@/components/ChatwootWidget';

export default function RootLayout({ children }) {
  return (
    <html lang="es">
      <body>
        {children}
        <ChatwootWidget 
          websiteToken={process.env.NEXT_PUBLIC_CHATWOOT_TOKEN || ''}
          baseUrl={process.env.NEXT_PUBLIC_CHATWOOT_URL || 'http://localhost:3000'}
          settings={{
            position: 'right',
            locale: 'es'
          }}
        />
      </body>
    </html>
  );
}
```

Agrega a tu `.env.local`:

```env
NEXT_PUBLIC_CHATWOOT_URL=http://localhost:3000
NEXT_PUBLIC_CHATWOOT_TOKEN=tu_website_token_aqui
```

### Opción 2: Iframe Embebido

Si prefieres un iframe en una página específica:

```typescript
// components/ChatwootEmbed.tsx
'use client';

interface ChatwootEmbedProps {
  websiteToken: string;
  baseUrl?: string;
  height?: string;
  width?: string;
}

export default function ChatwootEmbed({
  websiteToken,
  baseUrl = 'http://localhost:3000',
  height = '600px',
  width = '100%'
}: ChatwootEmbedProps) {
  const iframeUrl = `${baseUrl}/widget?website_token=${websiteToken}`;

  return (
    <div className="chatwoot-embed-container">
      <iframe
        src={iframeUrl}
        style={{
          width,
          height,
          border: 'none',
          borderRadius: '8px'
        }}
        title="Chat de Soporte"
        allow="microphone; camera"
      />
    </div>
  );
}
```

Uso en una página:

```typescript
// app/soporte/page.tsx
import ChatwootEmbed from '@/components/ChatwootEmbed';

export default function SoportePage() {
  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Chat de Soporte</h1>
      <ChatwootEmbed
        websiteToken={process.env.NEXT_PUBLIC_CHATWOOT_TOKEN || ''}
        baseUrl={process.env.NEXT_PUBLIC_CHATWOOT_URL || ''}
        height="700px"
      />
    </div>
  );
}
```

## 🎨 Personalización del Widget

### Cambiar Colores y Apariencia

En Chatwoot Admin Panel:
1. Ve a Settings → Inboxes → [Tu Widget]
2. En "Widget Customization":
   - Color del widget
   - Mensaje de bienvenida
   - Avatar
   - etc.

### Configuración Avanzada vía JavaScript

```javascript
window.chatwootSettings = {
  // Ocultar el bubble inicial
  hideMessageBubble: false,
  
  // Posición del widget
  position: 'right', // 'left' or 'right'
  
  // Idioma
  locale: 'es',
  
  // Tipo de widget
  type: 'standard', // 'standard' or 'expanded_bubble'
  
  // Color personalizado (hex)
  widgetColor: '#667eea',
  
  // Launcher title
  launcherTitle: 'Chatea con nosotros',
  
  // Mostrar el widget solo en ciertas páginas
  showPopoutButton: true,
};
```

## 🔐 Autenticación de Usuarios

Para identificar automáticamente a tus usuarios de Ticket Ace Portal en Chatwoot:

```typescript
// Después de que el usuario inicie sesión
useEffect(() => {
  if (user && window.$chatwoot) {
    window.$chatwoot.setUser(user.id, {
      name: user.name,
      email: user.email,
      avatar_url: user.avatar,
      // Custom attributes
      role: user.role,
      company: user.company,
      phone: user.phone,
    });
  }
}, [user]);
```

### Con HMAC Verification (Más Seguro)

1. En Chatwoot, habilita "Enforce User Identity Validation" en el widget
2. Genera un HMAC identifier en tu backend:

```typescript
// Backend: api/chatwoot/generate-token.ts
import crypto from 'crypto';

export function generateChatwootHMAC(userId: string): string {
  const secret = process.env.CHATWOOT_IDENTITY_VALIDATION_SECRET || '';
  return crypto
    .createHmac('sha256', secret)
    .update(userId)
    .digest('hex');
}
```

3. En el frontend:

```typescript
// Obtén el HMAC desde tu API
const hmac = await fetch('/api/chatwoot/generate-token', {
  method: 'POST',
  body: JSON.stringify({ userId: user.id })
}).then(r => r.json());

window.$chatwoot.setUser(user.id, {
  name: user.name,
  email: user.email,
  identifier_hash: hmac, // HMAC verification
});
```

## 📊 Eventos y Analytics

### Escuchar Eventos del Widget

```typescript
useEffect(() => {
  window.addEventListener('chatwoot:ready', () => {
    console.log('Chatwoot está listo');
  });

  window.addEventListener('chatwoot:on-message', (e) => {
    console.log('Nuevo mensaje:', e.detail);
    // Puedes enviar a tu analytics
  });

  window.addEventListener('chatwoot:on-conversation-end', () => {
    console.log('Conversación finalizada');
  });
}, []);
```

### Controlar el Widget Programáticamente

```typescript
// Abrir el widget
window.$chatwoot.toggle('open');

// Cerrar el widget
window.$chatwoot.toggle('close');

// Toggle (abrir/cerrar)
window.$chatwoot.toggle();

// Restablecer conversación (logout)
window.$chatwoot.reset();

// Enviar evento personalizado
window.$chatwoot.setCustomAttributes({
  current_page: window.location.pathname,
  ticket_id: currentTicket?.id,
  plan: userPlan,
});
```

## 🧪 Testing

### 1. Prueba Local

```bash
# Terminal 1: Chatwoot
cd /Users/ian.hdzzz/Desktop/chatwootCEA
docker-compose up

# Terminal 2: Ticket Ace Portal Frontend
cd /Users/ian.hdzzz/ticket-ace-portal-10225/Frontend
npm run dev
```

Visita `http://localhost:3001` (o tu puerto) y verifica que el widget aparece.

### 2. Verificar en DevTools

Abre la consola (F12) y ejecuta:

```javascript
// Verificar que el SDK está cargado
console.log(window.$chatwoot);

// Ver configuración actual
console.log(window.chatwootSettings);
```

### 3. Debugging

Si el widget no aparece:

```javascript
// 1. Verificar errores CSP
// Busca en consola: "Refused to frame..."

// 2. Verificar que el script se cargó
console.log(document.querySelector('script[src*="sdk.js"]'));

// 3. Verificar estado
console.log(window.chatwootSDK);
console.log(window.$chatwoot);
```

## 🚢 Despliegue en Producción

### Variables de Entorno

#### Chatwoot (Cloud Run / Docker)

```env
FRONTEND_URL=https://chatwoot.tudominio.com
ALLOWED_FRAME_ANCESTORS=https://ticket-portal.tudominio.com,https://www.ticket-portal.tudominio.com
ENABLE_API_CORS=true
```

#### Ticket Ace Portal

```env
NEXT_PUBLIC_CHATWOOT_URL=https://chatwoot.tudominio.com
NEXT_PUBLIC_CHATWOOT_TOKEN=production_token_here
```

### Actualizar Cloud Run

```bash
# Chatwoot
cd /Users/ian.hdzzz/Desktop/chatwootCEA
gcloud run services update chatwoot \
  --set-env-vars="ALLOWED_FRAME_ANCESTORS=https://ticket-portal.tudominio.com" \
  --region=us-central1

# Verificar
gcloud run services describe chatwoot --region=us-central1 --format="value(spec.template.spec.containers[0].env)"
```

## 📝 Checklist de Integración

- [ ] Chatwoot configurado con ALLOWED_FRAME_ANCESTORS
- [ ] Widget creado en Chatwoot (Settings → Inboxes → New Inbox → Website)
- [ ] Website Token obtenido
- [ ] Variables de entorno configuradas en Frontend
- [ ] Componente ChatwootWidget creado
- [ ] Widget agregado al layout
- [ ] Probado en desarrollo local
- [ ] CSP verificado (sin errores en consola)
- [ ] Autenticación de usuarios implementada (opcional)
- [ ] Probado en producción
- [ ] Analytics/eventos configurados (opcional)

## 🆘 Troubleshooting

### El widget no aparece

1. ✅ Verifica que Chatwoot esté corriendo
2. ✅ Revisa el token del website
3. ✅ Verifica ALLOWED_FRAME_ANCESTORS
4. ✅ Revisa errores en consola del navegador

### Error "Refused to frame"

```
Refused to frame 'http://localhost:3000' because it violates the 
following Content Security Policy directive: "frame-ancestors 'self'"
```

**Solución**: Agrega el origen en ALLOWED_FRAME_ANCESTORS:

```env
ALLOWED_FRAME_ANCESTORS=http://localhost:3001
```

### Widget aparece pero no carga mensajes

1. ✅ Verifica que el token sea correcto
2. ✅ Revisa la configuración del inbox en Chatwoot
3. ✅ Verifica que el inbox esté habilitado

### CORS errors al hacer API calls

**Solución**: Asegúrate de tener:

```env
ENABLE_API_CORS=true
```

## 📚 Referencias

- [Chatwoot Widget SDK](https://www.chatwoot.com/docs/product/channels/live-chat/sdk/setup)
- [Next.js Documentation](https://nextjs.org/docs)
- [CSP Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)

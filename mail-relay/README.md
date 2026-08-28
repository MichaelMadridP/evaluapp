# EvaluApp Mail Relay

Cloudflare Worker que recibe reportes ya generados por EvaluApp, verifica el
Firebase ID Token, limita el uso por usuario y envía HTML + texto mediante
Resend. El Worker no contiene lógica académica ni plantillas del reporte.

## Requisitos

- Node.js y npm.
- Una cuenta de Cloudflare con Wrangler autenticado.
- Un proyecto Firebase Authentication ya utilizado por EvaluApp.
- Una cuenta Resend, un dominio remitente verificado y una API key.

## Instalación y pruebas

```bash
npm install
npm run check
npm test
```

Los tests son unitarios, usan claves RSA efímeras y dobles de KV/fetch. No
acceden a Firebase, Google ni Resend y nunca envían emails reales.

## Configuración de Cloudflare

1. Autenticar Wrangler:

   ```bash
   npx wrangler login
   ```

2. Crear el namespace KV usado para el límite diario:

   ```bash
   npx wrangler kv namespace create RATE_LIMIT
   ```

3. Copiar el `id` devuelto en el binding `RATE_LIMIT` de `wrangler.jsonc`.

4. Reemplazar en `wrangler.jsonc` los valores de configuración:

   - `FIREBASE_PROJECT_ID`: Project ID exacto de Firebase (no el número de
     proyecto ni el App ID).
   - `RESEND_FROM_EMAIL`: dirección perteneciente a un dominio verificado en
     Resend.
   - `RESEND_FROM_NAME`: nombre visible del remitente.

5. Guardar la API key sólo como secret de Cloudflare:

   ```bash
   npx wrangler secret put RESEND_API_KEY
   ```

No colocar la API key en `wrangler.jsonc`, Git, Flutter, assets ni
`--dart-define`.

## Desarrollo local y despliegue

```bash
npx wrangler dev
npx wrangler deploy
```

Para una prueba manual local que necesite Resend, Wrangler admite variables
locales no versionadas; `.dev.vars*` está ignorado por Git. No se incluye ningún
valor real en este repositorio. Los tests automatizados deben seguir usando
mocks.

Después del deploy, comprobar el endpoint sin datos sensibles:

```bash
curl https://WORKER_URL/health
```

## Endpoints y respuestas

- `GET /health`: diagnóstico básico.
- `POST /send`: requiere `Authorization: Bearer <Firebase ID Token>` y JSON con
  `to`, `subject`, `html` y `text`.

Éxito:

```json
{"success":true,"messageId":"..."}
```

Error estable:

```json
{"success":false,"error":{"code":"RATE_LIMITED","message":"Daily email limit reached."}}
```

El remitente siempre se construye desde `RESEND_FROM_EMAIL` y
`RESEND_FROM_NAME`; el cliente no puede cambiarlo.

## Seguridad y límites

- Firma Firebase `RS256` verificada con los certificados oficiales de Google.
- Validación de `exp`, `iat`, `aud`, `iss`, `sub` y `auth_time`.
- Certificados cacheados en memoria durante el `max-age` indicado por Google.
- Máximo 5 destinatarios, 200 caracteres de asunto, 200 KiB de HTML, 100 KiB
  de texto y 310 KiB por request.
- Máximo 10 envíos diarios por `uid`, obtenido exclusivamente del JWT
  verificado.
- Timeout de 15 segundos hacia Resend.
- Errores públicos sin cuerpos de Resend, tokens, claves ni contenido
  académico.

### Decisión de rate limiting

Se usa Workers KV porque el volumen esperado es bajo y evita incorporar D1 o
Durable Objects. La clave es `fecha UTC + uid` y expira tras finalizar el día.
KV no ofrece incrementos atómicos; si en el futuro existen envíos concurrentes
altos o se necesita un límite estrictamente transaccional, debe migrarse este
componente aislado a Durable Objects. Esta limitación no afecta otras funciones
de EvaluApp.

# World Empire Backend Refactor Notes

This build keeps your existing API behaviour, database schema, Docker setup, seed data, and PostgreSQL workflow, but splits the server into clean modules.

## What changed

Old structure:

```txt
src/server.js     one large file with API routes + websocket + economy startup
```

New structure:

```txt
src/app.js                         Express app setup
src/server.js                      HTTP server + WebSocket + economy startup
src/routes/auth.routes.js          login/register
src/routes/world.routes.js         /api/world
src/routes/cities.routes.js        city details, claim city, city settings
src/routes/properties.routes.js    buy property, create business
src/routes/businesses.routes.js    restock businesses
src/routes/admin.routes.js         dev-only admin logs and bank freeze
src/websocket/index.js             authenticated WebSocket + chat
src/services/broadcaster.js        shared broadcast helper
src/middleware/errorHandler.js     validation and server error responses
```

## Why this is better

- Easier to add new features without breaking unrelated systems.
- Admin, city, property, business, and auth logic are separated.
- WebSocket broadcasting can be reused from any route.
- Zod validation errors now return useful JSON instead of crashing noisily.
- Unknown routes now return `route_not_found`.

## Existing endpoints preserved

- `GET /health`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/world`
- `GET /api/cities/:id`
- `POST /api/cities/:id/claim`
- `POST /api/cities/:id/settings`
- `POST /api/properties/:id/buy`
- `POST /api/properties/:id/business`
- `POST /api/businesses/:id/restock`
- `POST /api/admin/freeze-bank/:bankId`
- `GET /api/admin/logs`

## How to use

1. Back up your current server folder.
2. Replace it with this refactored folder.
3. Copy your `.env` into this folder.
4. Run:

```bash
npm install
npm run check
npm start
```

Or with Docker:

```bash
docker compose up --build
```

## Quick tests

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/health"

$response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"email":"ctrickett050983@gmail.com","password":"Apples1@"}'

$token = $response.token

Invoke-RestMethod -Uri "http://localhost:3000/api/world" `
  -Headers @{ Authorization = "Bearer $token" }

Invoke-RestMethod -Uri "http://localhost:3000/api/admin/logs" `
  -Headers @{ Authorization = "Bearer $token" }
```

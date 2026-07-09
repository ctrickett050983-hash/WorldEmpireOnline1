# Steam/PC Client Endpoints

Base URL while testing locally:

```text
http://localhost:3000
```

WebSocket URL:

```text
ws://localhost:3000?token=PLAYER_JWT
```

## Basic flow

1. Register or login.
2. Store the returned JWT token in the client.
3. Use `Authorization: Bearer TOKEN` for REST calls.
4. Connect WebSocket with `?token=TOKEN` for live messages.

## Useful routes

```text
GET  /health
POST /api/auth/register
POST /api/auth/login
GET  /api/world
GET  /api/cities/:id
POST /api/cities/:id/claim
POST /api/cities/:id/settings
POST /api/properties/:id/buy
POST /api/properties/:id/business
POST /api/businesses/:id/restock
POST /api/admin/freeze-bank/:bankId
GET  /api/admin/logs
```

## Example register body

```json
{
  "email": "player@example.com",
  "password": "Password123!",
  "displayName": "Player One"
}
```

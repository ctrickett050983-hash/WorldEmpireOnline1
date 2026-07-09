# Stage 2.2 - Character Server Fix

This patch wires the character API into the modular server.

## Files to copy

Copy the `server/` folder in this ZIP over your repo's `server/` folder and let Windows merge/replace files.

Important files:

- `server/src/routes/characters.routes.js` - new character API route
- `server/src/routes/index.js` - registers `/api/characters`
- `server/src/migrate.js` - now applies all SQL files in `server/sql/`
- `server/sql/002_characters.sql` - character table migration

## Run after copying

From your repo's `server/` folder:

```powershell
npm run migrate
npm start
```

## Test

```powershell
$response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"email":"player1@example.com","password":"Password123!"}'

$token = $response.token

Invoke-RestMethod -Uri "http://localhost:3000/api/characters/me" `
  -Headers @{ Authorization = "Bearer $token" }
```

Expected if no character exists:

```json
{"error":"character_not_found"}
```

That is good. It means the route is working and the Godot client should open character creation.

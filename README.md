# World Empire Online - Stage 2

Stage 2 adds persistent character creation after login.

## Client changes

Copy the `client/` folder into your repo.

New flow:

1. Login/register.
2. Load `/api/world`.
3. Check `GET /api/characters/me`.
4. If no character exists, open character creation.
5. Save to `POST /api/characters/create`.
6. Continue to city select.

## Server changes required

Before testing the client, add the Stage 2 server patch.

### Database

Run:

```sql
\i server_stage2_patch/migrations/002_characters.sql
```

Or paste the SQL into pgAdmin/query tool.

### Routes

If you are still using the single-file `server.js`, you can replace it with:

`server_stage2_patch/drop_in_single_file_server/server.js`

If you are using the refactored backend, copy the routes from:

`server_stage2_patch/characters_route_snippet.js`

into your character route module or main app and mount it with the same paths.

## Test

1. Start PostgreSQL.
2. Start your server.
3. Open Godot.
4. Log in with an existing player.
5. If no character exists, the character creator opens.
6. Create character.
7. You should continue to city selection.

## PowerShell endpoint test

```powershell
$response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"email":"player1@example.com","password":"Password123!"}'

$token = $response.token

Invoke-RestMethod -Uri "http://localhost:3000/api/characters/me" `
  -Headers @{ Authorization = "Bearer $token" }
```

If you have not created a character yet, this should return `character_not_found`.

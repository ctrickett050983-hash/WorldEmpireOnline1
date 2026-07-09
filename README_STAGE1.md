# World Empire Online - Stage 1 Launch/Login Flow

Copy the `client/` folder into your GitHub repo, replacing the current client folder after backing it up.

## What changed

- New launch screen: `res://scenes/Launch.tscn`
- Polished login/register UI
- Server health check using `/health`
- Remember-me local settings using `user://session_settings.json`
- Safer session handling in `scripts/session.gd`
- Loading steps before entering city select
- Friendlier login/register/world-load errors

## Test

1. Start your Node/PostgreSQL server.
2. Open `client/` in Godot 4.
3. Press Play.
4. Confirm `Server: online`.
5. Login with your working account.
6. Expected result: it loads `/api/world`, then opens city selection.

## Notes

This stage keeps your existing Sprint 3 district, property, phone, and chat systems intact.

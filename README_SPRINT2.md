# World Empire Online - Sprint 2 Client Update

This update builds on Sprint 1 and adds a stronger playable city foundation.

## Added

- Improved third-person controller with sprint.
- Press `E` near buildings to inspect properties.
- Press `P` or click Phone to open the phone UI.
- Phone apps: City, Property, Business, Bank placeholders.
- Building signs generated from live server property data.
- Safer property inspection and purchase flow.
- Cleaner city HUD for future gameplay systems.

## Controls

- WASD: move
- Mouse: camera
- Space: jump
- Shift: sprint
- E: inspect nearby property
- P: phone
- Esc: release mouse

## How to install into your GitHub repo

1. Back up your current `client/` folder.
2. Copy this ZIP's `client/` folder over your repo's `client/` folder.
3. Open `client/` in Godot 4.
4. Run your Node server.
5. Press Play and log in.

## Server routes used

- `POST /api/auth/login`
- `POST /api/auth/register`
- `GET /api/world`
- `GET /api/cities/:id`
- `POST /api/properties/:id/buy`
- `ws://localhost:3000?token=...`

## Next Sprint

- Real character creation saved to PostgreSQL.
- Other player replication through WebSockets.
- Business creation UI.
- Bank UI with dev oversight.
- Better 3D art pass.

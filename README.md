# World Empire Online - Sprint 3 Client

This is a Godot 4 client update for Sprint 3.

## What it adds

- Better login/register screen
- Server URL input
- Session/API/Realtime autoloads
- World city selection
- 3D district scene
- WASD movement
- Shift sprint
- Space jump
- Mouse camera
- E property interaction
- Buy property flow through your Node/PostgreSQL server
- P phone UI shell
- T chat panel with WebSocket support
- Procedural city district using your server property data
- Building labels and prices

## Install

1. Back up your current `client` folder.
2. Copy this `client` folder into your repository.
3. Start your Node.js server.
4. Open `client/project.godot` in Godot 4.
5. Press Play.
6. Log in with your existing account.

## Controls

- WASD: move
- Mouse: camera
- Shift: sprint
- Space: jump
- E: inspect/buy nearby property
- P: phone
- T: chat
- Esc: release mouse

## Server endpoints used

- POST `/api/auth/login`
- POST `/api/auth/register`
- GET `/api/world`
- GET `/api/cities/:id`
- POST `/api/properties/:id/buy`
- WebSocket `ws://localhost:3000/?token=...`

## Notes

This is still a Sprint 3 foundation, not final Steam-quality gameplay. It gives you the full flow: login, choose city, spawn, walk, inspect properties, buy through the server, and receive live updates.

# World Empire Online - Godot 4 Client Starter

This starter client connects to your existing Node/PostgreSQL game server.

## What is included

- Godot 4 project
- Login screen
- Register button
- JWT token storage for the running session
- `/api/world` loading
- World scene listing cities
- Refresh and logout buttons

## How to use

1. Keep your Node server running on:

   http://localhost:3000

2. Open Godot 4.
3. Import/open the project inside:

   `client/`

4. Press Play.
5. Login with the account that worked:

   `player1@example.com`
   `Password123!`

6. You should land on the World screen and see your cities.

## Important

The Godot client talks to your server only. It does not connect directly to PostgreSQL.

Next features to add:

- character creation
- player movement scene
- WebSocket chat
- city ownership actions
- property buying
- business management
- bank UI

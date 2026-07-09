# World Empire Online - Sprint 1 Client Foundation

This package adds a stronger Godot 4 client foundation:

- login/register against your Node server
- configurable server URL
- global Session autoload
- shared ApiClient autoload
- world map/city selection
- city detail loading via `/api/cities/:id`
- simple 3D playable district
- WASD third-person movement
- property list and buy action
- WebSocket city chat panel

## How to use

1. Keep your Node/PostgreSQL server running on `http://localhost:3000`.
2. Open `client/` in Godot 4.
3. Run the project.
4. Log in with your working account.
5. Choose a city and press **Enter Selected City**.
6. Walk with WASD, mouse to look, Space to jump, Esc to release mouse.

## Copy into GitHub repo

Copy this `client/` folder over your repository's `client/` folder, then commit:

```bash
git add client README_SPRINT1.md
git commit -m "Add Sprint 1 Godot client foundation"
git push
```

# Stage 2.1 Character Flow Patch

This patch fixes the login flow so it checks `/api/characters/me` after `/api/world`.

Expected flow:

1. Login/register
2. Load world cities
3. Check character
4. If no character exists, open `CharacterCreate.tscn`
5. If a character exists, continue to `CitySelect.tscn`

It also supports both server behaviours:

- `404` when no character exists
- `200` with `{ "character": null }` when no character exists

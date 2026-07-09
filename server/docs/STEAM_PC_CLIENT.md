# Steam/PC Client Integration Notes

The game client should treat the server as authoritative.

## Recommended client flow

1. Show login/register screen.
2. Send login/register request to server.
3. Store returned JWT in memory.
4. Fetch `/api/world`.
5. Open WebSocket with `?token=JWT`.
6. Render cities, properties, businesses, banks, chat, and player state.
7. Send game actions through REST endpoints.
8. Apply WebSocket broadcasts to update the UI in real time.

## Steam auth later

For Steam release, replace email/password login or add a second login route:

```text
POST /api/auth/steam
```

The client sends a Steam authentication ticket. The server verifies it with Steam, then creates/loads the linked user.

## Anti-cheat rule

Never let the client say:

- "I now have £1,000,000"
- "I own this city"
- "This business made £50,000"

The client should only ask for an action:

- buy property
- create business
- restock
- request loan
- accept trade

The server checks if the action is allowed.

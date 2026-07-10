# World Empire Online - Unreal Engine 5 Client Starter

This changes the client direction from Godot to Unreal Engine 5 while keeping your Node.js/PostgreSQL server.

## What stays the same

Your backend should stay as the source of truth:

- PostgreSQL database
- Node.js server
- JWT authentication
- `/api/auth/login`
- `/api/auth/register`
- `/api/world`
- `/api/cities/:id`
- `/api/characters/me`
- `/api/characters/create`
- `/api/properties/:id/buy`
- WebSocket chat

## What this Unreal starter includes

- UE5 C++ project shell
- `UWEOGameInstance` API client
- Login/register functions callable from Blueprint
- Character load/create functions callable from Blueprint
- World and city loading functions callable from Blueprint
- Property buying function callable from Blueprint
- WebSocket connect/chat functions callable from Blueprint
- Third-person character C++ class
- Input mappings for WASD, sprint, jump, interact, phone

## How to use

1. Unzip this folder.
2. Open `WorldEmpireOnline.uproject` in Unreal Engine 5.
3. Let Unreal generate project files.
4. Compile from Visual Studio/Rider or from Unreal.
5. Create UMG widgets and call the Blueprint functions on `WEOGameInstance`.

## Recommended Blueprint flow

### Main Menu Widget

Call:

```text
Get Game Instance -> Cast to WEOGameInstance -> Login(email, password)
```

Bind to:

```text
OnApiMessage
OnCharacterLoaded
OnWorldLoaded
```

### After login

The GameInstance automatically calls:

```text
GET /api/characters/me
```

If the message is `character_required`, show character creation.

### Character creation

Call:

```text
CreateCharacter(firstName, lastName, startingCityId)
```

### World map

Use the `Cities` array after `OnWorldLoaded` fires.

### City

Call:

```text
LoadCity(cityId)
```

Then use `CurrentCityProperties` to spawn property markers/buildings.

## Important

Do not connect Unreal directly to PostgreSQL. Unreal should only talk to the Node.js server.

## Next stage

The next stage should add:

- UMG login widget
- UMG character creator widget
- UMG city select widget
- A starter Unreal map
- Blueprint building/property marker actor
- Property purchase prompt

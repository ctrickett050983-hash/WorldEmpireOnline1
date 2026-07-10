# No-WebSockets Compatibility Build

This version removes the required `WebSockets` plugin from `WorldEmpireOnline.uproject` so the project can open on Unreal installs where that plugin is missing.

## What still works

- Login/register through HTTP
- Character loading/creation through HTTP
- World/city loading through HTTP
- Property buying through HTTP
- Third-person player class

## Temporarily disabled

- Realtime WebSocket chat

After the project opens and compiles, chat can be restored later using either Unreal's built-in WebSockets plugin, a third-party plugin, or HTTP polling.

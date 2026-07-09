# World Empire Game Server Starter

This is a clean **PostgreSQL + Node.js authoritative multiplayer server starter** for your Steam/PC game.

It is designed for a player-run economy game where:

- one player can own and maintain a city
- other players buy/rent homes and businesses inside that city
- businesses produce income using stock, wages, prices, staff, and demand
- banks can be player-run
- the developer keeps oversight through dev-only admin controls
- the world continues ticking while players are offline

## What is included

- Express REST API
- WebSocket real-time server
- PostgreSQL schema
- account registration/login
- JWT authentication
- player-owned cities
- city taxes
- property buying
- business creation
- bank records
- dev-only bank freeze control
- admin logs
- persistent economy ticks
- chat over WebSocket
- world seeding

## Local setup

1. Install PostgreSQL.
2. Create a database:

```bash
createdb world_empire
```

3. Copy environment file:

```bash
cp .env.example .env
```

4. Edit `.env` and set your PostgreSQL connection:

```bash
DATABASE_URL=postgres://postgres:postgres@localhost:5432/world_empire
JWT_SECRET=make-this-a-long-random-secret
DEV_EMAIL=your@email.com
DEV_PASSWORD=YourStrongPassword123!
```

5. Install packages:

```bash
npm install
```

6. Create tables:

```bash
npm run migrate
```

7. Seed starter cities and dev user:

```bash
npm run seed
```

8. Start server:

```bash
npm start
```

Server runs at:

```text
http://localhost:3000
```

Health check:

```text
GET /health
```

## REST API overview

### Register

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "player@example.com",
  "password": "Password123!",
  "displayName": "Cameron"
}
```

### Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "player@example.com",
  "password": "Password123!"
}
```

Use the returned token as:

```http
Authorization: Bearer YOUR_TOKEN
```

### Get world cities

```http
GET /api/world
Authorization: Bearer YOUR_TOKEN
```

### Claim a city

```http
POST /api/cities/:id/claim
Authorization: Bearer YOUR_TOKEN
```

### Change city tax settings

Only the city owner or dev can do this.

```http
POST /api/cities/:id/settings
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "business_tax": 9,
  "property_tax": 5
}
```

### Buy property

```http
POST /api/properties/:id/buy
Authorization: Bearer YOUR_TOKEN
```

### Create business in owned property

```http
POST /api/properties/:id/business
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "name": "Cameron's Corner Shop",
  "type": "retail"
}
```

Allowed business types:

- retail
- restaurant
- factory
- logistics
- bank
- real_estate

### Restock business

```http
POST /api/businesses/:id/restock
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "amount": 250
}
```

### Dev freeze bank

Only users with role `dev` can do this.

```http
POST /api/admin/freeze-bank/:bankId
Authorization: Bearer DEV_TOKEN
Content-Type: application/json

{
  "frozen": true,
  "note": "Suspicious loan activity"
}
```

### Dev admin logs

```http
GET /api/admin/logs
Authorization: Bearer DEV_TOKEN
```

## WebSocket protocol

Connect from your Steam/PC client using:

```text
ws://localhost:3000?token=YOUR_JWT_TOKEN
```

### Send city chat

```json
{
  "type": "chat",
  "cityId": "CITY_UUID",
  "message": "Anyone renting shop space?"
}
```

### Server broadcasts

Examples:

```json
{ "type": "economy_tick", "summary": { } }
```

```json
{ "type": "property_bought", "propertyId": "...", "userId": "..." }
```

```json
{ "type": "chat", "cityId": "...", "name": "Cameron", "message": "Hello" }
```

## How this connects to a Steam/PC client

For Unity, Unreal, Godot, or your own launcher:

1. Client logs in through REST.
2. Client stores JWT securely for the session.
3. Client fetches `/api/world`.
4. Client opens WebSocket using the JWT.
5. Client sends actions through REST for important economy changes.
6. Server broadcasts real-time changes through WebSocket.

Important rule: **do not trust the client**. The server owns money, property, cities, stock, taxes, bank balances, and trades.

## Next systems to add

These are the next best upgrades:

1. Steam login using Steamworks auth tickets
2. proper trades with accept/reject escrow
3. loans and repayments
4. property rental contracts
5. city service budgets
6. logistics and deliveries
7. item inventories
8. staff hiring and player jobs
9. anti-cheat transaction audit rules
10. admin web dashboard


## Easiest setup added

I added helper files so you do not have to manually wire everything together:

- `setup-and-run.bat` for Windows local setup
- `setup-and-run.sh` for Mac/Linux local setup
- `docker-compose.yml` for PostgreSQL + server in one command
- `docker-entrypoint.sh` so Docker automatically migrates and seeds the database
- `QUICK_START.md` for the fastest instructions
- `POSTGRES_HELP.md` for database connection help
- `CLIENT_ENDPOINTS.md` for Steam/PC client integration

Fastest Docker command:

```bash
docker compose up --build
```

Fastest Windows local command: double-click `setup-and-run.bat`.

Fastest Mac/Linux local command:

```bash
./setup-and-run.sh
```

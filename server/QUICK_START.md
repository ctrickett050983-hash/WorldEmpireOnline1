# Quick Start

## Easiest option: Docker Desktop

1. Install Docker Desktop.
2. Open a terminal in this folder.
3. Run:

```bash
docker compose up --build
```

This starts PostgreSQL, creates the database tables, adds starter cities/properties, creates the dev account, and starts the server.

Server health check:

```text
http://localhost:3000/health
```

Default dev login from `docker-compose.yml`:

```text
owner@example.com
ChangeMe123!
```

Change these before publishing online.

## Windows without Docker

1. Install Node.js LTS.
2. Install PostgreSQL.
3. Create a database called `world_empire`.
4. Double-click `setup-and-run.bat`.

## Mac/Linux without Docker

```bash
chmod +x setup-and-run.sh
./setup-and-run.sh
```

## Important

This is a starter authoritative server, not a finished commercial backend yet. Before real launch you still need stronger auth, rate limits, Steam auth, backups, server monitoring, and production security hardening.

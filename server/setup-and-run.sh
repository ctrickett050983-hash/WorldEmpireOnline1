#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo "World Empire Game Server - Mac/Linux Setup"
echo "=========================================="

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is not installed. Install Node.js LTS, then run this again."
  exit 1
fi

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example"
  echo "Edit .env if your PostgreSQL username/password/database are different."
fi

echo "Installing dependencies..."
npm install

echo "Applying database schema..."
npm run migrate

echo "Adding starter cities/properties/dev account..."
npm run seed

echo "Starting server..."
npm start

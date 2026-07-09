#!/usr/bin/env sh
set -e

echo "Waiting for PostgreSQL..."
node -e "const {Pool}=require('pg'); const url=process.env.DATABASE_URL; let tries=0; const wait=()=>{ const p=new Pool({connectionString:url}); p.query('select 1').then(()=>p.end()).then(()=>process.exit(0)).catch(()=>{p.end().catch(()=>{}); if(++tries>60) process.exit(1); setTimeout(wait,1000);});}; wait();"

echo "Running migrations and seed..."
node src/migrate.js
node src/seed.js

echo "Starting game server..."
node src/server.js

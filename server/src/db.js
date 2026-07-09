const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function query(text, params) {
  const started = Date.now();
  try {
    const res = await pool.query(text, params);
    const ms = Date.now() - started;
    if (ms > 250) console.warn('slow query', { ms, text: text.slice(0, 120) });
    return res;
  } catch (err) {
    console.error('db error', err.message, text);
    throw err;
  }
}

module.exports = { pool, query };

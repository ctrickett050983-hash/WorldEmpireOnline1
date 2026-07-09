const fs = require('fs');
const path = require('path');
require('dotenv').config();
const { pool } = require('./db');
(async () => {
  const sql = fs.readFileSync(path.join(__dirname, '..', 'sql', 'schema.sql'), 'utf8');
  await pool.query(sql);
  console.log('Database schema applied.');
  await pool.end();
})().catch(err => { console.error(err); process.exit(1); });

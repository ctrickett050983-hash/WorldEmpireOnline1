const fs = require('fs');
const path = require('path');
require('dotenv').config();
const { pool } = require('./db');

(async () => {
  const sqlDir = path.join(__dirname, '..', 'sql');
  const files = fs
    .readdirSync(sqlDir)
    .filter(file => file.endsWith('.sql'))
    .sort((a, b) => {
      if (a === 'schema.sql') return -1;
      if (b === 'schema.sql') return 1;
      return a.localeCompare(b);
    });

  for (const file of files) {
    const sql = fs.readFileSync(path.join(sqlDir, file), 'utf8');
    await pool.query(sql);
    console.log(`Applied ${file}`);
  }

  await pool.end();
})().catch(err => {
  console.error(err);
  process.exit(1);
});

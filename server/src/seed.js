require('dotenv').config();
const { query, pool } = require('./db');
const { hashPassword } = require('./auth');

async function main() {
  const devEmail = process.env.DEV_EMAIL || 'owner@example.com';
  const devPass = process.env.DEV_PASSWORD || 'ChangeMe123!';
  const pw = await hashPassword(devPass);
  await query(`INSERT INTO users(email,password_hash,display_name,role,cash)
    VALUES($1,$2,'Developer','dev',1000000)
    ON CONFLICT(email) DO NOTHING`, [devEmail, pw]);

  const cities = [['London','United Kingdom'],['New York','United States'],['Tokyo','Japan'],['Paris','France'],['Dubai','UAE'],['Sydney','Australia']];
  for (const [name,country] of cities) {
    const city = await query(`INSERT INTO cities(name,country,population,happiness,safety,infrastructure,treasury)
      VALUES($1,$2,50000 + floor(random()*250000)::int,65,70,60,100000)
      ON CONFLICT DO NOTHING RETURNING id`, [name,country]);
    const cityId = city.rows[0]?.id || (await query('SELECT id FROM cities WHERE name=$1 AND country=$2 LIMIT 1',[name,country])).rows[0]?.id;
    if (!cityId) continue;
    const kinds = ['home','shop','office','warehouse','factory','bank_branch'];
    for (let i=0;i<12;i++) {
      const kind = kinds[i % kinds.length];
      await query(`INSERT INTO properties(city_id,kind,name,value,rent,upkeep)
        SELECT $1,$2,$3,$4,$5,$6 WHERE NOT EXISTS (SELECT 1 FROM properties WHERE city_id=$1 AND name=$3)`,
        [cityId, kind, `${name} ${kind} ${i+1}`, 40000+i*7500, 900+i*120, 80+i*10]);
    }
  }
  console.log('Seed complete. Dev login:', devEmail, '/', devPass);
}
main().then(()=>pool.end()).catch(err=>{ console.error(err); process.exit(1); });

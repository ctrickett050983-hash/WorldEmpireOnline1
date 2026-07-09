require('dotenv').config();
const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const WebSocket = require('ws');
const { z } = require('zod');
const { query } = require('./db');
const { sign, verify, requireAuth, requireDev, hashPassword, comparePassword } = require('./auth');
const { runEconomyTick } = require('./economy');

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/health', (_, res) => res.json({ ok: true, name: 'world-empire-game-server' }));

app.post('/api/auth/register', async (req, res) => {
  const body = z.object({ email: z.string().email(), password: z.string().min(8), displayName: z.string().min(2).max(32) }).parse(req.body);
  const passwordHash = await hashPassword(body.password);
  try {
    const { rows } = await query('INSERT INTO users(email,password_hash,display_name) VALUES($1,$2,$3) RETURNING id,email,display_name,role,cash', [body.email.toLowerCase(), passwordHash, body.displayName]);
    res.json({ token: sign(rows[0]), user: rows[0] });
  } catch (e) { res.status(409).json({ error: 'email_taken' }); }
});

app.post('/api/auth/login', async (req, res) => {
  const body = z.object({ email: z.string().email(), password: z.string() }).parse(req.body);
  const { rows } = await query('SELECT * FROM users WHERE email=$1', [body.email.toLowerCase()]);
  const user = rows[0];
  if (!user || !(await comparePassword(body.password, user.password_hash))) return res.status(401).json({ error: 'bad_login' });
  await query('UPDATE users SET last_seen_at=now() WHERE id=$1', [user.id]);
  res.json({ token: sign(user), user: { id: user.id, email: user.email, display_name: user.display_name, role: user.role, cash: user.cash } });
});

app.get('/api/world', requireAuth, async (_, res) => {
  const cities = (await query(`SELECT c.*, u.display_name AS owner_name FROM cities c LEFT JOIN users u ON c.owner_user_id=u.id ORDER BY c.name`)).rows;
  res.json({ cities });
});

app.get('/api/characters/me', requireAuth, async (req, res) => {
  const character = (await query('SELECT * FROM characters WHERE user_id=$1', [req.user.id])).rows[0];
  if (!character) return res.status(404).json({ error: 'character_not_found' });
  res.json({ character });
});

app.post('/api/characters/create', requireAuth, async (req, res) => {
  const body = z.object({
    first_name: z.string().min(2).max(32),
    last_name: z.string().min(2).max(32),
    date_of_birth: z.string().optional(),
    nationality: z.string().min(2).max(60),
    gender: z.string().min(2).max(32),
    starting_city_id: z.string().uuid(),
    hair: z.string().min(1).max(40),
    beard: z.string().min(1).max(40),
    eyes: z.string().min(1).max(40),
    skin_tone: z.string().min(1).max(40),
    clothes: z.string().min(1).max(40),
    shoes: z.string().min(1).max(40)
  }).parse(req.body);
  const existing = (await query('SELECT id FROM characters WHERE user_id=$1', [req.user.id])).rows[0];
  if (existing) return res.status(409).json({ error: 'character_exists' });
  const city = (await query('SELECT id FROM cities WHERE id=$1', [body.starting_city_id])).rows[0];
  if (!city) return res.status(404).json({ error: 'starting_city_not_found' });
  const { rows } = await query(
    `INSERT INTO characters(user_id, first_name, last_name, date_of_birth, nationality, gender, starting_city_id, hair, beard, eyes, skin_tone, clothes, shoes)
     VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) RETURNING *`,
    [req.user.id, body.first_name, body.last_name, body.date_of_birth || null, body.nationality, body.gender, body.starting_city_id, body.hair, body.beard, body.eyes, body.skin_tone, body.clothes, body.shoes]
  );
  res.json({ character: rows[0] });
});

app.put('/api/characters/update', requireAuth, async (req, res) => {
  const body = z.object({
    hair: z.string().min(1).max(40).optional(),
    beard: z.string().min(1).max(40).optional(),
    eyes: z.string().min(1).max(40).optional(),
    skin_tone: z.string().min(1).max(40).optional(),
    clothes: z.string().min(1).max(40).optional(),
    shoes: z.string().min(1).max(40).optional(),
    position_x: z.number().optional(),
    position_y: z.number().optional(),
    position_z: z.number().optional()
  }).parse(req.body);
  const current = (await query('SELECT * FROM characters WHERE user_id=$1', [req.user.id])).rows[0];
  if (!current) return res.status(404).json({ error: 'character_not_found' });
  const merged = { ...current, ...body };
  const { rows } = await query(
    `UPDATE characters SET hair=$1, beard=$2, eyes=$3, skin_tone=$4, clothes=$5, shoes=$6, position_x=$7, position_y=$8, position_z=$9, updated_at=now()
     WHERE user_id=$10 RETURNING *`,
    [merged.hair, merged.beard, merged.eyes, merged.skin_tone, merged.clothes, merged.shoes, merged.position_x, merged.position_y, merged.position_z, req.user.id]
  );
  res.json({ character: rows[0] });
});

app.get('/api/cities/:id', requireAuth, async (req, res) => {
  const city = (await query('SELECT * FROM cities WHERE id=$1', [req.params.id])).rows[0];
  if (!city) return res.status(404).json({ error: 'not_found' });
  const properties = (await query('SELECT * FROM properties WHERE city_id=$1 ORDER BY kind,name', [req.params.id])).rows;
  const businesses = (await query('SELECT * FROM businesses WHERE city_id=$1 ORDER BY name', [req.params.id])).rows;
  res.json({ city, properties, businesses });
});

app.post('/api/cities/:id/claim', requireAuth, async (req, res) => {
  const city = (await query('SELECT * FROM cities WHERE id=$1', [req.params.id])).rows[0];
  if (!city) return res.status(404).json({ error: 'not_found' });
  if (city.owner_user_id) return res.status(409).json({ error: 'city_already_owned' });
  const cost = 250000;
  if (Number(req.user.cash) < cost) return res.status(400).json({ error: 'not_enough_cash', cost });
  await query('BEGIN');
  try {
    await query('UPDATE users SET cash=cash-$1 WHERE id=$2', [cost, req.user.id]);
    await query('UPDATE cities SET owner_user_id=$1, treasury=treasury+$2 WHERE id=$3', [req.user.id, cost, req.params.id]);
    await query('COMMIT');
    broadcast({ type: 'city_claimed', cityId: req.params.id, userId: req.user.id });
    res.json({ ok: true });
  } catch(e) { await query('ROLLBACK'); throw e; }
});

app.post('/api/cities/:id/settings', requireAuth, async (req, res) => {
  const body = z.object({ business_tax: z.number().min(0).max(25), property_tax: z.number().min(0).max(15) }).parse(req.body);
  const city = (await query('SELECT * FROM cities WHERE id=$1', [req.params.id])).rows[0];
  if (!city) return res.status(404).json({ error: 'not_found' });
  if (city.owner_user_id !== req.user.id && req.user.role !== 'dev') return res.status(403).json({ error: 'city_owner_only' });
  await query('UPDATE cities SET business_tax=$1, property_tax=$2, updated_at=now() WHERE id=$3', [body.business_tax, body.property_tax, req.params.id]);
  broadcast({ type: 'city_settings_changed', cityId: req.params.id, settings: body });
  res.json({ ok: true });
});

app.post('/api/properties/:id/buy', requireAuth, async (req, res) => {
  const p = (await query('SELECT * FROM properties WHERE id=$1', [req.params.id])).rows[0];
  if (!p || !p.is_for_sale) return res.status(404).json({ error: 'not_for_sale' });
  if (p.owner_user_id === req.user.id) return res.status(400).json({ error: 'already_owned' });
  if (Number(req.user.cash) < Number(p.value)) return res.status(400).json({ error: 'not_enough_cash' });
  await query('BEGIN');
  try {
    await query('UPDATE users SET cash=cash-$1 WHERE id=$2', [p.value, req.user.id]);
    if (p.owner_user_id) await query('UPDATE users SET cash=cash+$1 WHERE id=$2', [p.value, p.owner_user_id]);
    await query('UPDATE properties SET owner_user_id=$1,is_for_sale=false WHERE id=$2', [req.user.id, p.id]);
    await query('COMMIT');
    broadcast({ type: 'property_bought', propertyId: p.id, userId: req.user.id });
    res.json({ ok: true });
  } catch(e) { await query('ROLLBACK'); throw e; }
});

app.post('/api/properties/:id/business', requireAuth, async (req, res) => {
  const body = z.object({ name: z.string().min(2).max(40), type: z.enum(['retail','restaurant','factory','logistics','bank','real_estate']) }).parse(req.body);
  const p = (await query('SELECT * FROM properties WHERE id=$1', [req.params.id])).rows[0];
  if (!p || p.owner_user_id !== req.user.id) return res.status(403).json({ error: 'must_own_property' });
  const { rows } = await query('INSERT INTO businesses(property_id,owner_user_id,city_id,type,name) VALUES($1,$2,$3,$4,$5) RETURNING *', [p.id, req.user.id, p.city_id, body.type, body.name]);
  if (body.type === 'bank') await query('INSERT INTO banks(business_id) VALUES($1)', [rows[0].id]);
  broadcast({ type: 'business_created', business: rows[0] });
  res.json({ business: rows[0] });
});

app.post('/api/businesses/:id/restock', requireAuth, async (req, res) => {
  const body = z.object({ amount: z.number().int().min(1).max(10000) }).parse(req.body);
  const b = (await query('SELECT * FROM businesses WHERE id=$1', [req.params.id])).rows[0];
  if (!b || b.owner_user_id !== req.user.id) return res.status(403).json({ error: 'business_owner_only' });
  const cost = body.amount * 8;
  if (Number(b.cash) < cost) return res.status(400).json({ error: 'business_cash_low', cost });
  await query('UPDATE businesses SET cash=cash-$1, stock=stock+$2 WHERE id=$3', [cost, body.amount, b.id]);
  broadcast({ type: 'business_restocked', businessId: b.id, amount: body.amount });
  res.json({ ok: true });
});

app.post('/api/admin/freeze-bank/:bankId', requireAuth, requireDev, async (req, res) => {
  const body = z.object({ frozen: z.boolean(), note: z.string().max(300).optional() }).parse(req.body);
  await query('UPDATE banks SET frozen_by_dev=$1, dev_note=$2 WHERE id=$3', [body.frozen, body.note || null, req.params.bankId]);
  await query('INSERT INTO admin_logs(actor_user_id,action,target_type,target_id,details) VALUES($1,$2,$3,$4,$5)', [req.user.id, body.frozen ? 'freeze_bank' : 'unfreeze_bank', 'bank', req.params.bankId, body]);
  broadcast({ type: 'admin_bank_status', bankId: req.params.bankId, frozen: body.frozen });
  res.json({ ok: true });
});

app.get('/api/admin/logs', requireAuth, requireDev, async (_, res) => {
  const rows = (await query('SELECT * FROM admin_logs ORDER BY created_at DESC LIMIT 100')).rows;
  res.json({ logs: rows });
});

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });
const sockets = new Map();
function broadcast(payload) {
  const json = JSON.stringify(payload);
  for (const ws of sockets.keys()) if (ws.readyState === WebSocket.OPEN) ws.send(json);
}
wss.on('connection', (ws, req) => {
  try {
    const url = new URL(req.url, 'http://localhost');
    const token = url.searchParams.get('token');
    const user = verify(token);
    sockets.set(ws, user);
    ws.send(JSON.stringify({ type: 'hello', user }));
    ws.on('message', async raw => {
      try {
        const msg = JSON.parse(raw.toString());
        if (msg.type === 'chat') {
          const text = String(msg.message || '').slice(0, 300).trim();
          if (!text) return;
          await query('INSERT INTO chat_messages(city_id,user_id,message) VALUES($1,$2,$3)', [msg.cityId || null, user.id, text]);
          broadcast({ type: 'chat', cityId: msg.cityId || null, userId: user.id, name: user.name, message: text, at: new Date().toISOString() });
        }
      } catch { ws.send(JSON.stringify({ type: 'error', error: 'bad_message' })); }
    });
    ws.on('close', () => sockets.delete(ws));
  } catch { ws.close(1008, 'auth required'); }
});

const tickMs = Math.max(10, Number(process.env.TICK_SECONDS || 30)) * 1000;
setInterval(() => runEconomyTick(broadcast).catch(console.error), tickMs);

const port = Number(process.env.PORT || 3000);
server.listen(port, () => console.log(`World Empire server running on :${port}`));

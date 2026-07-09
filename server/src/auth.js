const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { query } = require('./db');

function sign(user) {
  return jwt.sign({ id: user.id, role: user.role, name: user.display_name }, process.env.JWT_SECRET, { expiresIn: '7d' });
}
function verify(token) { return jwt.verify(token, process.env.JWT_SECRET); }
async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) return res.status(401).json({ error: 'missing_token' });
    const payload = verify(token);
    const { rows } = await query('SELECT id,email,display_name,role,cash FROM users WHERE id=$1', [payload.id]);
    if (!rows[0]) return res.status(401).json({ error: 'invalid_user' });
    req.user = rows[0];
    next();
  } catch { res.status(401).json({ error: 'invalid_token' }); }
}
function requireDev(req, res, next) {
  if (!req.user || req.user.role !== 'dev') return res.status(403).json({ error: 'dev_only' });
  next();
}
async function hashPassword(password) { return bcrypt.hash(password, 12); }
async function comparePassword(password, hash) { return bcrypt.compare(password, hash); }
module.exports = { sign, verify, requireAuth, requireDev, hashPassword, comparePassword };

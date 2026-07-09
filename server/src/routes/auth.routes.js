const express = require('express');
const { z } = require('zod');
const { query } = require('../db');
const { sign, hashPassword, comparePassword } = require('../auth');

const router = express.Router();

router.post('/register', async (req, res, next) => {
  try {
    const body = z.object({
      email: z.string().email(),
      password: z.string().min(8),
      displayName: z.string().min(2).max(32)
    }).parse(req.body);

    const passwordHash = await hashPassword(body.password);
    const { rows } = await query(
      'INSERT INTO users(email,password_hash,display_name) VALUES($1,$2,$3) RETURNING id,email,display_name,role,cash',
      [body.email.toLowerCase(), passwordHash, body.displayName]
    );
    res.json({ token: sign(rows[0]), user: rows[0] });
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'email_taken' });
    next(e);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const body = z.object({ email: z.string().email(), password: z.string() }).parse(req.body);
    const { rows } = await query('SELECT * FROM users WHERE email=$1', [body.email.toLowerCase()]);
    const user = rows[0];
    if (!user || !(await comparePassword(body.password, user.password_hash))) {
      return res.status(401).json({ error: 'bad_login' });
    }
    await query('UPDATE users SET last_seen_at=now() WHERE id=$1', [user.id]);
    res.json({
      token: sign(user),
      user: { id: user.id, email: user.email, display_name: user.display_name, role: user.role, cash: user.cash }
    });
  } catch (e) { next(e); }
});

module.exports = router;

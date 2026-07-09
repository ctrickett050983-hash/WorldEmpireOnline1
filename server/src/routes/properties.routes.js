const express = require('express');
const { z } = require('zod');
const { query } = require('../db');
const { requireAuth } = require('../auth');
const broadcaster = require('../services/broadcaster');

const router = express.Router();

router.post('/:id/buy', requireAuth, async (req, res, next) => {
  try {
    const p = (await query('SELECT * FROM properties WHERE id=$1', [req.params.id])).rows[0];
    if (!p || !p.is_for_sale) return res.status(404).json({ error: 'not_for_sale' });
    if (p.owner_user_id === req.user.id) return res.status(400).json({ error: 'already_owned' });
    if (Number(req.user.cash) < Number(p.value)) return res.status(400).json({ error: 'not_enough_cash' });

    await query('BEGIN');
    await query('UPDATE users SET cash=cash-$1 WHERE id=$2', [p.value, req.user.id]);
    if (p.owner_user_id) await query('UPDATE users SET cash=cash+$1 WHERE id=$2', [p.value, p.owner_user_id]);
    await query('UPDATE properties SET owner_user_id=$1,is_for_sale=false WHERE id=$2', [req.user.id, p.id]);
    await query('COMMIT');

    broadcaster.broadcast({ type: 'property_bought', propertyId: p.id, userId: req.user.id });
    res.json({ ok: true });
  } catch (e) {
    await query('ROLLBACK').catch(() => {});
    next(e);
  }
});

router.post('/:id/business', requireAuth, async (req, res, next) => {
  try {
    const body = z.object({
      name: z.string().min(2).max(40),
      type: z.enum(['retail','restaurant','factory','logistics','bank','real_estate'])
    }).parse(req.body);
    const p = (await query('SELECT * FROM properties WHERE id=$1', [req.params.id])).rows[0];
    if (!p || p.owner_user_id !== req.user.id) return res.status(403).json({ error: 'must_own_property' });
    const { rows } = await query(
      'INSERT INTO businesses(property_id,owner_user_id,city_id,type,name) VALUES($1,$2,$3,$4,$5) RETURNING *',
      [p.id, req.user.id, p.city_id, body.type, body.name]
    );
    if (body.type === 'bank') await query('INSERT INTO banks(business_id) VALUES($1)', [rows[0].id]);
    broadcaster.broadcast({ type: 'business_created', business: rows[0] });
    res.json({ business: rows[0] });
  } catch (e) { next(e); }
});

module.exports = router;

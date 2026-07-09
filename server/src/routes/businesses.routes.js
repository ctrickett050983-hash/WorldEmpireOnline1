const express = require('express');
const { z } = require('zod');
const { query } = require('../db');
const { requireAuth } = require('../auth');
const broadcaster = require('../services/broadcaster');

const router = express.Router();

router.post('/:id/restock', requireAuth, async (req, res, next) => {
  try {
    const body = z.object({ amount: z.number().int().min(1).max(10000) }).parse(req.body);
    const b = (await query('SELECT * FROM businesses WHERE id=$1', [req.params.id])).rows[0];
    if (!b || b.owner_user_id !== req.user.id) return res.status(403).json({ error: 'business_owner_only' });
    const cost = body.amount * 8;
    if (Number(b.cash) < cost) return res.status(400).json({ error: 'business_cash_low', cost });
    await query('UPDATE businesses SET cash=cash-$1, stock=stock+$2 WHERE id=$3', [cost, body.amount, b.id]);
    broadcaster.broadcast({ type: 'business_restocked', businessId: b.id, amount: body.amount });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

module.exports = router;

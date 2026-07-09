const express = require('express');
const { z } = require('zod');
const { query } = require('../db');
const { requireAuth } = require('../auth');
const broadcaster = require('../services/broadcaster');

const router = express.Router();

router.get('/:id', requireAuth, async (req, res, next) => {
  try {
    const city = (await query('SELECT * FROM cities WHERE id=$1', [req.params.id])).rows[0];
    if (!city) return res.status(404).json({ error: 'not_found' });
    const properties = (await query('SELECT * FROM properties WHERE city_id=$1 ORDER BY kind,name', [req.params.id])).rows;
    const businesses = (await query('SELECT * FROM businesses WHERE city_id=$1 ORDER BY name', [req.params.id])).rows;
    res.json({ city, properties, businesses });
  } catch (e) { next(e); }
});

router.post('/:id/claim', requireAuth, async (req, res, next) => {
  const cost = 250000;
  try {
    const city = (await query('SELECT * FROM cities WHERE id=$1', [req.params.id])).rows[0];
    if (!city) return res.status(404).json({ error: 'not_found' });
    if (city.owner_user_id) return res.status(409).json({ error: 'city_already_owned' });
    if (Number(req.user.cash) < cost) return res.status(400).json({ error: 'not_enough_cash', cost });

    await query('BEGIN');
    await query('UPDATE users SET cash=cash-$1 WHERE id=$2', [cost, req.user.id]);
    await query('UPDATE cities SET owner_user_id=$1, treasury=treasury+$2 WHERE id=$3', [req.user.id, cost, req.params.id]);
    await query('COMMIT');

    broadcaster.broadcast({ type: 'city_claimed', cityId: req.params.id, userId: req.user.id });
    res.json({ ok: true });
  } catch (e) {
    await query('ROLLBACK').catch(() => {});
    next(e);
  }
});

router.post('/:id/settings', requireAuth, async (req, res, next) => {
  try {
    const body = z.object({
      business_tax: z.number().min(0).max(25),
      property_tax: z.number().min(0).max(15)
    }).parse(req.body);
    const city = (await query('SELECT * FROM cities WHERE id=$1', [req.params.id])).rows[0];
    if (!city) return res.status(404).json({ error: 'not_found' });
    if (city.owner_user_id !== req.user.id && req.user.role !== 'dev') {
      return res.status(403).json({ error: 'city_owner_only' });
    }
    await query('UPDATE cities SET business_tax=$1, property_tax=$2, updated_at=now() WHERE id=$3', [body.business_tax, body.property_tax, req.params.id]);
    broadcaster.broadcast({ type: 'city_settings_changed', cityId: req.params.id, settings: body });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

module.exports = router;

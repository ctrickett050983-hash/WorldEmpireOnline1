const express = require('express');
const { z } = require('zod');
const { query } = require('../db');
const { requireAuth, requireDev } = require('../auth');
const broadcaster = require('../services/broadcaster');

const router = express.Router();

router.post('/freeze-bank/:bankId', requireAuth, requireDev, async (req, res, next) => {
  try {
    const body = z.object({ frozen: z.boolean(), note: z.string().max(300).optional() }).parse(req.body);
    await query('UPDATE banks SET frozen_by_dev=$1, dev_note=$2 WHERE id=$3', [body.frozen, body.note || null, req.params.bankId]);
    await query(
      'INSERT INTO admin_logs(actor_user_id,action,target_type,target_id,details) VALUES($1,$2,$3,$4,$5)',
      [req.user.id, body.frozen ? 'freeze_bank' : 'unfreeze_bank', 'bank', req.params.bankId, body]
    );
    broadcaster.broadcast({ type: 'admin_bank_status', bankId: req.params.bankId, frozen: body.frozen });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

router.get('/logs', requireAuth, requireDev, async (req, res, next) => {
  try {
    const rows = (await query('SELECT * FROM admin_logs ORDER BY created_at DESC LIMIT 100')).rows;
    res.json({ logs: rows });
  } catch (e) { next(e); }
});

module.exports = router;

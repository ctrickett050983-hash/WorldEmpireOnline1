const express = require('express');
const { query } = require('../db');
const { requireAuth } = require('../auth');

const router = express.Router();

router.get('/', requireAuth, async (req, res, next) => {
  try {
    const cities = (await query(`
      SELECT c.*, u.display_name AS owner_name
      FROM cities c
      LEFT JOIN users u ON c.owner_user_id=u.id
      ORDER BY c.name
    `)).rows;
    res.json({ cities });
  } catch (e) { next(e); }
});

module.exports = router;

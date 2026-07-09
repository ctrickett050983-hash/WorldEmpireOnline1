const express = require('express');
const { z } = require('zod');
const { query } = require('../db');
const { requireAuth } = require('../auth');

const router = express.Router();

router.get('/me', requireAuth, async (req, res, next) => {
  try {
    const { rows } = await query('SELECT * FROM characters WHERE user_id=$1', [req.user.id]);
    if (!rows[0]) return res.status(404).json({ error: 'character_not_found' });
    res.json({ character: rows[0] });
  } catch (e) {
    next(e);
  }
});

router.post('/create', requireAuth, async (req, res, next) => {
  try {
    const body = z.object({
      first_name: z.string().min(2).max(32),
      last_name: z.string().min(2).max(32),
      date_of_birth: z.string().optional().nullable(),
      nationality: z.string().min(2).max(60).default('Unknown'),
      gender: z.string().min(2).max(32).default('Unspecified'),
      starting_city_id: z.string().uuid(),
      hair: z.string().min(1).max(40).default('Short'),
      beard: z.string().min(1).max(40).default('None'),
      eyes: z.string().min(1).max(40).default('Brown'),
      skin_tone: z.string().min(1).max(40).default('Medium'),
      clothes: z.string().min(1).max(40).default('Casual'),
      shoes: z.string().min(1).max(40).default('Trainers')
    }).parse(req.body);

    const existing = (await query('SELECT id FROM characters WHERE user_id=$1', [req.user.id])).rows[0];
    if (existing) return res.status(409).json({ error: 'character_exists' });

    const city = (await query('SELECT id FROM cities WHERE id=$1', [body.starting_city_id])).rows[0];
    if (!city) return res.status(404).json({ error: 'starting_city_not_found' });

    const { rows } = await query(
      `INSERT INTO characters(
        user_id, first_name, last_name, date_of_birth, nationality, gender,
        starting_city_id, hair, beard, eyes, skin_tone, clothes, shoes
      ) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
      RETURNING *`,
      [
        req.user.id,
        body.first_name,
        body.last_name,
        body.date_of_birth || null,
        body.nationality,
        body.gender,
        body.starting_city_id,
        body.hair,
        body.beard,
        body.eyes,
        body.skin_tone,
        body.clothes,
        body.shoes
      ]
    );

    res.json({ character: rows[0] });
  } catch (e) {
    next(e);
  }
});

router.put('/update', requireAuth, async (req, res, next) => {
  try {
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
      `UPDATE characters SET
        hair=$1, beard=$2, eyes=$3, skin_tone=$4, clothes=$5, shoes=$6,
        position_x=$7, position_y=$8, position_z=$9, updated_at=now()
      WHERE user_id=$10 RETURNING *`,
      [
        merged.hair,
        merged.beard,
        merged.eyes,
        merged.skin_tone,
        merged.clothes,
        merged.shoes,
        merged.position_x,
        merged.position_y,
        merged.position_z,
        req.user.id
      ]
    );

    res.json({ character: rows[0] });
  } catch (e) {
    next(e);
  }
});

module.exports = router;

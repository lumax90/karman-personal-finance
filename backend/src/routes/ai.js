const express = require('express');
const { z } = require('zod');
const prisma = require('../config/prisma');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();
router.use(authenticate);

// ─── GET /ai/keys ────────────────────────────────────────

router.get('/keys', async (req, res) => {
  try {
    const keys = await prisma.aiApiKey.findMany({
      where: { userId: req.user.id },
      select: { model: true, updatedAt: true },
    });
    // Return which models have keys stored (not the actual keys)
    res.json({ data: keys.map((k) => ({ model: k.model, hasKey: true, updatedAt: k.updatedAt })) });
  } catch (err) {
    console.error('Get AI keys error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── PUT /ai/keys/:model ─────────────────────────────────

const keySchema = z.object({
  apiKey: z.string().min(1).max(500),
});

router.put('/keys/:model', validate(keySchema), async (req, res) => {
  try {
    const model = req.params.model;
    if (!['grok', 'gemini', 'openai'].includes(model)) {
      return res.status(400).json({ error: 'Invalid model' });
    }

    await prisma.aiApiKey.upsert({
      where: { userId_model: { userId: req.user.id, model } },
      update: { apiKey: req.body.apiKey },
      create: { userId: req.user.id, model, apiKey: req.body.apiKey },
    });

    res.json({ message: 'API key saved' });
  } catch (err) {
    console.error('Save AI key error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── DELETE /ai/keys/:model ──────────────────────────────

router.delete('/keys/:model', async (req, res) => {
  try {
    const model = req.params.model;
    await prisma.aiApiKey.deleteMany({
      where: { userId: req.user.id, model },
    });
    res.json({ message: 'API key deleted' });
  } catch (err) {
    console.error('Delete AI key error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── GET /ai/keys/:model/value ───────────────────────────
// Returns actual key value (for the app to use in AI calls)

router.get('/keys/:model/value', async (req, res) => {
  try {
    const model = req.params.model;
    const record = await prisma.aiApiKey.findUnique({
      where: { userId_model: { userId: req.user.id, model } },
    });
    if (!record) return res.status(404).json({ error: 'No key found' });

    res.json({ apiKey: record.apiKey });
  } catch (err) {
    console.error('Get AI key value error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;

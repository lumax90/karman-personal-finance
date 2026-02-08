const express = require('express');
const { z } = require('zod');
const prisma = require('../config/prisma');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();
router.use(authenticate);

const subscriptionSchema = z.object({
  name: z.string().min(1).max(200),
  amount: z.number().positive(),
  cycle: z.enum(['monthly', 'yearly']),
  startDate: z.string().transform((s) => new Date(s)),
  nextPaymentDate: z.string().transform((s) => new Date(s)),
  category: z.string().max(100).optional().nullable(),
  isActive: z.boolean().optional(),
  accountMode: z.enum(['personal', 'business']),
});

// ─── GET /subscriptions ──────────────────────────────────

router.get('/', async (req, res) => {
  try {
    const { accountMode, active } = req.query;
    const where = { userId: req.user.id };
    if (accountMode) where.accountMode = accountMode;
    if (active !== undefined) where.isActive = active === 'true';

    const subscriptions = await prisma.subscription.findMany({
      where,
      orderBy: { nextPaymentDate: 'asc' },
    });

    const totalMonthly = subscriptions
      .filter((s) => s.isActive)
      .reduce((sum, s) => sum + (s.cycle === 'yearly' ? s.amount / 12 : s.amount), 0);

    res.json({ data: subscriptions, totalMonthly });
  } catch (err) {
    console.error('Get subscriptions error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── POST /subscriptions ─────────────────────────────────

router.post('/', validate(subscriptionSchema), async (req, res) => {
  try {
    const subscription = await prisma.subscription.create({
      data: { ...req.body, userId: req.user.id },
    });
    res.status(201).json({ data: subscription });
  } catch (err) {
    console.error('Create subscription error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── PUT /subscriptions/:id ──────────────────────────────

router.put('/:id', validate(subscriptionSchema), async (req, res) => {
  try {
    const existing = await prisma.subscription.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    const subscription = await prisma.subscription.update({
      where: { id: req.params.id },
      data: req.body,
    });
    res.json({ data: subscription });
  } catch (err) {
    console.error('Update subscription error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── DELETE /subscriptions/:id ───────────────────────────

router.delete('/:id', async (req, res) => {
  try {
    const existing = await prisma.subscription.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    await prisma.subscription.delete({ where: { id: req.params.id } });
    res.json({ message: 'Deleted' });
  } catch (err) {
    console.error('Delete subscription error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;

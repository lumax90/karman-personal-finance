const express = require('express');
const { z } = require('zod');
const prisma = require('../config/prisma');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();
router.use(authenticate);

const goalSchema = z.object({
  title: z.string().min(1).max(200),
  type: z.enum(['income', 'expense', 'savings', 'revenue', 'profit']),
  targetAmount: z.number().positive(),
  currentAmount: z.number().min(0).optional().nullable(),
  startDate: z.string().transform((s) => new Date(s)),
  endDate: z.string().transform((s) => new Date(s)),
  period: z.enum(['monthly', 'yearly']).optional().nullable(),
  isActive: z.boolean().optional().nullable(),
});

router.get('/', async (req, res) => {
  try {
    const { active } = req.query;
    const where = { userId: req.user.id };
    if (active !== undefined) where.isActive = active === 'true';

    const goals = await prisma.goal.findMany({ where, orderBy: { createdAt: 'desc' } });
    res.json({ data: goals });
  } catch (err) {
    console.error('Get goals error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/', validate(goalSchema), async (req, res) => {
  try {
    const goal = await prisma.goal.create({
      data: { ...req.body, userId: req.user.id },
    });
    res.status(201).json({ data: goal });
  } catch (err) {
    console.error('Create goal error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/:id', validate(goalSchema), async (req, res) => {
  try {
    const existing = await prisma.goal.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    const goal = await prisma.goal.update({ where: { id: req.params.id }, data: req.body });
    res.json({ data: goal });
  } catch (err) {
    console.error('Update goal error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const existing = await prisma.goal.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    await prisma.goal.delete({ where: { id: req.params.id } });
    res.json({ message: 'Deleted' });
  } catch (err) {
    console.error('Delete goal error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;

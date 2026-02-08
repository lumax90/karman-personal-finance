const express = require('express');
const { z } = require('zod');
const prisma = require('../config/prisma');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();
router.use(authenticate);

const activitySchema = z.object({
  contactId: z.string().uuid().optional().nullable(),
  type: z.enum(['call', 'email', 'meeting', 'task', 'note']),
  title: z.string().min(1).max(300),
  description: z.string().max(2000).optional().nullable(),
  date: z.string().transform((s) => new Date(s)),
  isCompleted: z.boolean().optional().nullable(),
  dealId: z.string().uuid().optional().nullable(),
});

// GET all activities
router.get('/', async (req, res) => {
  try {
    const { contactId } = req.query;
    const where = { userId: req.user.id };
    if (contactId) where.contactId = contactId;

    const activities = await prisma.activity.findMany({
      where,
      orderBy: { date: 'desc' },
    });
    res.json({ data: activities });
  } catch (err) {
    console.error('Get activities error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST create activity
router.post('/', validate(activitySchema), async (req, res) => {
  try {
    const activity = await prisma.activity.create({
      data: { ...req.body, userId: req.user.id },
    });
    res.status(201).json({ data: activity });
  } catch (err) {
    console.error('Create activity error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT update activity
router.put('/:id', validate(activitySchema), async (req, res) => {
  try {
    const existing = await prisma.activity.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    const activity = await prisma.activity.update({
      where: { id: req.params.id },
      data: req.body,
    });
    res.json({ data: activity });
  } catch (err) {
    console.error('Update activity error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PATCH toggle complete
router.patch('/:id/toggle', async (req, res) => {
  try {
    const existing = await prisma.activity.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    const activity = await prisma.activity.update({
      where: { id: req.params.id },
      data: { isCompleted: !existing.isCompleted },
    });
    res.json({ data: activity });
  } catch (err) {
    console.error('Toggle activity error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE activity
router.delete('/:id', async (req, res) => {
  try {
    const existing = await prisma.activity.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    await prisma.activity.delete({ where: { id: req.params.id } });
    res.json({ message: 'Deleted' });
  } catch (err) {
    console.error('Delete activity error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;

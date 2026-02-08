const express = require('express');
const { z } = require('zod');
const prisma = require('../config/prisma');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();
router.use(authenticate);

const reminderSchema = z.object({
  title: z.string().min(1).max(200),
  subtitle: z.string().max(500).optional().nullable(),
  dueDate: z.string().transform((s) => new Date(s)),
  type: z.enum(['invoiceDue', 'followUp', 'subscriptionRenewal', 'goalDeadline', 'custom']),
  isCompleted: z.boolean().optional().nullable(),
  linkedId: z.string().optional().nullable(),
});

router.get('/', async (req, res) => {
  try {
    const { completed, upcoming } = req.query;
    const where = { userId: req.user.id };
    if (completed !== undefined) where.isCompleted = completed === 'true';

    const orderBy = { dueDate: 'asc' };

    const reminders = await prisma.reminder.findMany({
      where,
      orderBy,
    });

    res.json({ data: reminders });
  } catch (err) {
    console.error('Get reminders error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/', validate(reminderSchema), async (req, res) => {
  try {
    const reminder = await prisma.reminder.create({
      data: { ...req.body, userId: req.user.id },
    });
    res.status(201).json({ data: reminder });
  } catch (err) {
    console.error('Create reminder error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/:id', validate(reminderSchema), async (req, res) => {
  try {
    const existing = await prisma.reminder.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    const reminder = await prisma.reminder.update({ where: { id: req.params.id }, data: req.body });
    res.json({ data: reminder });
  } catch (err) {
    console.error('Update reminder error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.patch('/:id/toggle', async (req, res) => {
  try {
    const existing = await prisma.reminder.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    const reminder = await prisma.reminder.update({
      where: { id: req.params.id },
      data: { isCompleted: !existing.isCompleted },
    });
    res.json({ data: reminder });
  } catch (err) {
    console.error('Toggle reminder error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const existing = await prisma.reminder.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    await prisma.reminder.delete({ where: { id: req.params.id } });
    res.json({ message: 'Deleted' });
  } catch (err) {
    console.error('Delete reminder error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;

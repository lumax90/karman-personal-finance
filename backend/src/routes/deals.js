const express = require('express');
const { z } = require('zod');
const prisma = require('../config/prisma');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();
router.use(authenticate);

const dealSchema = z.object({
  title: z.string().min(1).max(200),
  amount: z.number().positive(),
  stage: z.enum(['discovery', 'qualification', 'proposal', 'negotiation', 'closedWon', 'closedLost']).optional().nullable(),
  contactId: z.string().uuid().optional().nullable(),
  contactName: z.string().max(200).optional().nullable(),
  probability: z.number().min(0).max(100).optional().nullable(),
  expectedCloseDate: z.string().transform((s) => new Date(s)).optional().nullable(),
  notes: z.string().max(2000).optional().nullable(),
});

router.get('/', async (req, res) => {
  try {
    const { stage } = req.query;
    const where = { userId: req.user.id };
    if (stage) where.stage = stage;

    const deals = await prisma.deal.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: { contact: { select: { id: true, name: true, company: true } } },
    });

    // Pipeline summary
    const summary = {};
    for (const d of deals) {
      if (!summary[d.stage]) summary[d.stage] = { count: 0, total: 0 };
      summary[d.stage].count++;
      summary[d.stage].total += d.amount;
    }

    res.json({ data: deals, pipeline: summary });
  } catch (err) {
    console.error('Get deals error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/', validate(dealSchema), async (req, res) => {
  try {
    // Validate contact belongs to user if provided
    if (req.body.contactId) {
      const contact = await prisma.contact.findFirst({
        where: { id: req.body.contactId, userId: req.user.id },
      });
      if (!contact) return res.status(400).json({ error: 'Contact not found' });
    }

    const deal = await prisma.deal.create({
      data: { ...req.body, userId: req.user.id },
    });
    res.status(201).json({ data: deal });
  } catch (err) {
    console.error('Create deal error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/:id', validate(dealSchema), async (req, res) => {
  try {
    const existing = await prisma.deal.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    const deal = await prisma.deal.update({ where: { id: req.params.id }, data: req.body });
    res.json({ data: deal });
  } catch (err) {
    console.error('Update deal error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.patch('/:id/stage', async (req, res) => {
  try {
    const { stage } = req.body;
    if (!['discovery', 'qualification', 'proposal', 'negotiation', 'closedWon', 'closedLost'].includes(stage)) {
      return res.status(400).json({ error: 'Invalid stage' });
    }

    const existing = await prisma.deal.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    const deal = await prisma.deal.update({ where: { id: req.params.id }, data: { stage } });
    res.json({ data: deal });
  } catch (err) {
    console.error('Update deal stage error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const existing = await prisma.deal.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    await prisma.deal.delete({ where: { id: req.params.id } });
    res.json({ message: 'Deleted' });
  } catch (err) {
    console.error('Delete deal error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;

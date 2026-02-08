const express = require('express');
const { z } = require('zod');
const prisma = require('../config/prisma');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();
router.use(authenticate);

const contactSchema = z.object({
  name: z.string().min(1).max(200),
  email: z.string().email().optional().nullable(),
  phone: z.string().max(30).optional().nullable(),
  company: z.string().max(200).optional().nullable(),
  type: z.enum(['lead', 'client']).optional(),
  status: z.enum(['newLead', 'contacted', 'qualified', 'proposal', 'negotiation', 'won', 'lost', 'churned']).optional(),
  source: z.enum(['website', 'referral', 'social', 'cold', 'event', 'other']).optional(),
  tags: z.array(z.string()).optional(),
  notes: z.string().max(2000).optional().nullable(),
  totalRevenue: z.number().min(0).optional().nullable(),
  lastContactedAt: z.string().transform((s) => new Date(s)).optional().nullable(),
});

router.get('/', async (req, res) => {
  try {
    const { search, type } = req.query;
    const where = { userId: req.user.id };
    if (type) where.type = type;
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
        { company: { contains: search, mode: 'insensitive' } },
      ];
    }

    const contacts = await prisma.contact.findMany({
      where,
      orderBy: { name: 'asc' },
      include: {
        _count: { select: { deals: true } },
      },
    });

    res.json({ data: contacts });
  } catch (err) {
    console.error('Get contacts error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const contact = await prisma.contact.findFirst({
      where: { id: req.params.id, userId: req.user.id },
      include: {
        deals: { orderBy: { createdAt: 'desc' }, take: 10 },
      },
    });
    if (!contact) return res.status(404).json({ error: 'Not found' });
    res.json({ data: contact });
  } catch (err) {
    console.error('Get contact error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/', validate(contactSchema), async (req, res) => {
  try {
    const contact = await prisma.contact.create({
      data: { ...req.body, userId: req.user.id },
    });
    res.status(201).json({ data: contact });
  } catch (err) {
    console.error('Create contact error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/:id', validate(contactSchema), async (req, res) => {
  try {
    const existing = await prisma.contact.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    const contact = await prisma.contact.update({ where: { id: req.params.id }, data: req.body });
    res.json({ data: contact });
  } catch (err) {
    console.error('Update contact error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const existing = await prisma.contact.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    await prisma.contact.delete({ where: { id: req.params.id } });
    res.json({ message: 'Deleted' });
  } catch (err) {
    console.error('Delete contact error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;

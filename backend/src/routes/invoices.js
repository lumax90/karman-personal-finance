const express = require('express');
const { z } = require('zod');
const prisma = require('../config/prisma');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();
router.use(authenticate);

const invoiceItemSchema = z.object({
  description: z.string().min(1).max(500),
  quantity: z.number().int().positive(),
  unitPrice: z.number().positive(),
});

const invoiceSchema = z.object({
  invoiceNumber: z.string().min(1).max(50),
  contactId: z.string().uuid().optional().nullable(),
  contactName: z.string().min(1).max(200),
  items: z.array(invoiceItemSchema).min(1),
  taxRate: z.number().min(0).max(100).optional().nullable(),
  status: z.enum(['draft', 'sent', 'paid', 'overdue', 'cancelled']).optional().nullable(),
  issueDate: z.string().transform((s) => new Date(s)),
  dueDate: z.string().transform((s) => new Date(s)),
  paidDate: z.string().transform((s) => new Date(s)).optional().nullable(),
  notes: z.string().max(2000).optional().nullable(),
});

// GET all invoices
router.get('/', async (req, res) => {
  try {
    const invoices = await prisma.invoice.findMany({
      where: { userId: req.user.id },
      orderBy: { issueDate: 'desc' },
    });
    res.json({ data: invoices });
  } catch (err) {
    console.error('Get invoices error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST create invoice
router.post('/', validate(invoiceSchema), async (req, res) => {
  try {
    if (req.body.contactId) {
      const contact = await prisma.contact.findFirst({
        where: { id: req.body.contactId, userId: req.user.id },
      });
      if (!contact) return res.status(400).json({ error: 'Contact not found' });
    }

    const invoice = await prisma.invoice.create({
      data: { ...req.body, userId: req.user.id },
    });
    res.status(201).json({ data: invoice });
  } catch (err) {
    console.error('Create invoice error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT update invoice
router.put('/:id', validate(invoiceSchema), async (req, res) => {
  try {
    const existing = await prisma.invoice.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    const invoice = await prisma.invoice.update({
      where: { id: req.params.id },
      data: req.body,
    });
    res.json({ data: invoice });
  } catch (err) {
    console.error('Update invoice error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PATCH mark as paid
router.patch('/:id/paid', async (req, res) => {
  try {
    const existing = await prisma.invoice.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    const invoice = await prisma.invoice.update({
      where: { id: req.params.id },
      data: { status: 'paid', paidDate: new Date() },
    });
    res.json({ data: invoice });
  } catch (err) {
    console.error('Mark invoice paid error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PATCH mark as sent
router.patch('/:id/sent', async (req, res) => {
  try {
    const existing = await prisma.invoice.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    const invoice = await prisma.invoice.update({
      where: { id: req.params.id },
      data: { status: 'sent' },
    });
    res.json({ data: invoice });
  } catch (err) {
    console.error('Mark invoice sent error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE invoice
router.delete('/:id', async (req, res) => {
  try {
    const existing = await prisma.invoice.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    await prisma.invoice.delete({ where: { id: req.params.id } });
    res.json({ message: 'Deleted' });
  } catch (err) {
    console.error('Delete invoice error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;

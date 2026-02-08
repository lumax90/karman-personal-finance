const express = require('express');
const { z } = require('zod');
const prisma = require('../config/prisma');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const router = express.Router();
router.use(authenticate);

const transactionSchema = z.object({
  title: z.string().min(1).max(200),
  amount: z.number().positive(),
  type: z.enum(['income', 'expense']),
  category: z.enum([
    'salary', 'freelance', 'investment', 'rental', 'otherIncome',
    'rent', 'utilities', 'groceries', 'transport', 'entertainment',
    'health', 'education', 'shopping', 'food', 'sales', 'service',
    'consulting', 'commission', 'marketing', 'software', 'hosting',
    'office', 'equipment', 'taxes', 'insurance', 'payroll', 'subscription', 'other',
  ]),
  recurrence: z.enum(['once', 'daily', 'weekly', 'monthly', 'yearly']).optional(),
  isPaid: z.boolean().optional(),
  date: z.string().transform((s) => new Date(s)),
  notes: z.string().max(1000).optional().nullable(),
  accountMode: z.enum(['personal', 'business']),
});

// ─── GET /transactions ───────────────────────────────────

router.get('/', async (req, res) => {
  try {
    const { accountMode, type, from, to, limit = '50', offset = '0' } = req.query;

    const where = { userId: req.user.id };
    if (accountMode) where.accountMode = accountMode;
    if (type) where.type = type;
    if (from || to) {
      where.date = {};
      if (from) where.date.gte = new Date(from);
      if (to) where.date.lte = new Date(to);
    }

    const [transactions, total] = await Promise.all([
      prisma.transaction.findMany({
        where,
        orderBy: { date: 'desc' },
        take: Math.min(parseInt(limit), 100),
        skip: parseInt(offset),
      }),
      prisma.transaction.count({ where }),
    ]);

    res.json({ data: transactions, total });
  } catch (err) {
    console.error('Get transactions error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── GET /transactions/summary ───────────────────────────

router.get('/summary', async (req, res) => {
  try {
    const { accountMode } = req.query;
    const where = { userId: req.user.id };
    if (accountMode) where.accountMode = accountMode;

    const transactions = await prisma.transaction.findMany({ where });

    let totalIncome = 0;
    let totalExpense = 0;
    const byCategory = {};

    for (const t of transactions) {
      if (t.type === 'income') totalIncome += t.amount;
      else totalExpense += t.amount;

      byCategory[t.category] = (byCategory[t.category] || 0) + t.amount;
    }

    res.json({
      totalIncome,
      totalExpense,
      netBalance: totalIncome - totalExpense,
      savingsRate: totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome * 100) : 0,
      byCategory,
      transactionCount: transactions.length,
    });
  } catch (err) {
    console.error('Get summary error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── POST /transactions ──────────────────────────────────

router.post('/', validate(transactionSchema), async (req, res) => {
  try {
    const transaction = await prisma.transaction.create({
      data: { ...req.body, userId: req.user.id },
    });
    res.status(201).json({ data: transaction });
  } catch (err) {
    console.error('Create transaction error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── PUT /transactions/:id ───────────────────────────────

router.put('/:id', validate(transactionSchema), async (req, res) => {
  try {
    const existing = await prisma.transaction.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    const transaction = await prisma.transaction.update({
      where: { id: req.params.id },
      data: req.body,
    });
    res.json({ data: transaction });
  } catch (err) {
    console.error('Update transaction error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ─── DELETE /transactions/:id ────────────────────────────

router.delete('/:id', async (req, res) => {
  try {
    const existing = await prisma.transaction.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Not found' });

    await prisma.transaction.delete({ where: { id: req.params.id } });
    res.json({ message: 'Deleted' });
  } catch (err) {
    console.error('Delete transaction error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;

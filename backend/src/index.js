const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { PORT, NODE_ENV, CORS_ORIGIN } = require('./config/env');
const prisma = require('./config/prisma');

// Routes
const authRoutes = require('./routes/auth');
const transactionRoutes = require('./routes/transactions');
const subscriptionRoutes = require('./routes/subscriptions');
const goalRoutes = require('./routes/goals');
const reminderRoutes = require('./routes/reminders');
const contactRoutes = require('./routes/contacts');
const dealRoutes = require('./routes/deals');
const invoiceRoutes = require('./routes/invoices');
const activityRoutes = require('./routes/activities');
const aiRoutes = require('./routes/ai');
const webhookRoutes = require('./routes/webhook');

const app = express();

// ─── Security ────────────────────────────────────────────

app.use(helmet());
app.use(cors({ origin: CORS_ORIGIN, credentials: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later' },
});
app.use('/api/', limiter);

// Auth rate limit (stricter)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { error: 'Too many auth attempts, please try again later' },
});
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);

// ─── Body parsing ────────────────────────────────────────

app.use(express.json({ limit: '10mb' }));

// ─── Routes ──────────────────────────────────────────────

app.use('/api/auth', authRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/subscriptions', subscriptionRoutes);
app.use('/api/goals', goalRoutes);
app.use('/api/reminders', reminderRoutes);
app.use('/api/contacts', contactRoutes);
app.use('/api/deals', dealRoutes);
app.use('/api/invoices', invoiceRoutes);
app.use('/api/activities', activityRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/webhook', webhookRoutes);

// ─── Health check ────────────────────────────────────────

app.get('/api/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  } catch (err) {
    res.status(503).json({ status: 'error', message: 'Database unavailable' });
  }
});

// ─── 404 handler ─────────────────────────────────────────

app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// ─── Error handler ───────────────────────────────────────

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// ─── Start server ────────────────────────────────────────

const server = app.listen(PORT, () => {
  console.log(`🚀 Karman API running on port ${PORT} [${NODE_ENV}]`);
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} is already in use. Kill the other process and try again.`);
    process.exit(1);
  }
});

// Graceful shutdown — prevents EADDRINUSE on nodemon restart
const shutdown = (signal) => {
  console.log(`${signal} received. Shutting down...`);
  server.close(() => {
    prisma.$disconnect().finally(() => process.exit(0));
  });
  // Force exit after 1s if close hangs
  setTimeout(() => process.exit(0), 1000);
};

['SIGTERM', 'SIGHUP', 'SIGINT'].forEach((sig) => process.on(sig, () => shutdown(sig)));

// nodemon sends SIGUSR2 to restart — close server first, then let nodemon re-launch
process.once('SIGUSR2', () => {
  server.close(() => {
    prisma.$disconnect().finally(() => process.kill(process.pid, 'SIGUSR2'));
  });
  setTimeout(() => process.kill(process.pid, 'SIGUSR2'), 1000);
});

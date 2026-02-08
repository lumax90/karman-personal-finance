const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { JWT_SECRET, JWT_REFRESH_SECRET, JWT_EXPIRES_IN, JWT_REFRESH_EXPIRES_IN } = require('../config/env');
const prisma = require('../config/prisma');

function generateAccessToken(user) {
  return jwt.sign(
    {
      sub: user.id,
      email: user.email,
      tier: user.subscriptionTier,
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
}

function generateRefreshToken() {
  return crypto.randomBytes(40).toString('hex');
}

async function createRefreshToken(userId) {
  const token = generateRefreshToken();

  // Parse duration string like "7d" to milliseconds
  const match = JWT_REFRESH_EXPIRES_IN.match(/^(\d+)([dhms])$/);
  let ms = 7 * 24 * 60 * 60 * 1000; // default 7 days
  if (match) {
    const num = parseInt(match[1]);
    const unit = match[2];
    const multipliers = { d: 86400000, h: 3600000, m: 60000, s: 1000 };
    ms = num * (multipliers[unit] || 86400000);
  }

  const expiresAt = new Date(Date.now() + ms);

  await prisma.refreshToken.create({
    data: { token, userId, expiresAt },
  });

  return token;
}

async function verifyRefreshToken(token) {
  const record = await prisma.refreshToken.findUnique({
    where: { token },
    include: { user: true },
  });

  if (!record) return null;
  if (record.expiresAt < new Date()) {
    await prisma.refreshToken.delete({ where: { id: record.id } });
    return null;
  }

  return record;
}

async function revokeRefreshToken(token) {
  await prisma.refreshToken.deleteMany({ where: { token } });
}

async function revokeAllUserTokens(userId) {
  await prisma.refreshToken.deleteMany({ where: { userId } });
}

module.exports = {
  generateAccessToken,
  createRefreshToken,
  verifyRefreshToken,
  revokeRefreshToken,
  revokeAllUserTokens,
};

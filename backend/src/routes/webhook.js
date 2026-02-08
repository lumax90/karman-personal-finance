const express = require('express');
const prisma = require('../config/prisma');
const { REVENUECAT_WEBHOOK_SECRET } = require('../config/env');

const router = express.Router();

// ─── POST /webhook/revenuecat ────────────────────────────
// RevenueCat sends events when subscription status changes
// Docs: https://www.revenuecat.com/docs/integrations/webhooks

router.post('/revenuecat', async (req, res) => {
  try {
    // Verify webhook authorization
    const authHeader = req.headers.authorization;
    if (REVENUECAT_WEBHOOK_SECRET && authHeader !== `Bearer ${REVENUECAT_WEBHOOK_SECRET}`) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const event = req.body.event;
    if (!event) {
      return res.status(400).json({ error: 'Missing event' });
    }

    const { app_user_id, type } = event;
    console.log(`[RevenueCat] Event: ${type} for user: ${app_user_id}`);

    // Find user by RevenueCat customer ID or our user ID
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { rcCustomerId: app_user_id },
          { id: app_user_id },
        ],
      },
    });

    if (!user) {
      console.warn(`[RevenueCat] User not found: ${app_user_id}`);
      return res.status(200).json({ message: 'User not found, skipping' });
    }

    // Events that grant premium
    const premiumEvents = [
      'INITIAL_PURCHASE',
      'RENEWAL',
      'UNCANCELLATION',
      'NON_RENEWING_PURCHASE',
    ];

    // Events that revoke premium
    const freeEvents = [
      'EXPIRATION',
      'BILLING_ISSUE',
      'CANCELLATION', // Note: cancellation doesn't always mean immediate loss
    ];

    let newTier = null;

    if (premiumEvents.includes(type)) {
      newTier = 'premium';
    } else if (freeEvents.includes(type)) {
      // For CANCELLATION, check if there's still an active entitlement
      if (type === 'CANCELLATION') {
        // Don't downgrade immediately - user keeps access until expiration
        console.log(`[RevenueCat] Cancellation - user keeps access until period ends`);
        return res.status(200).json({ message: 'OK' });
      }
      newTier = 'free';
    }

    if (newTier) {
      await prisma.user.update({
        where: { id: user.id },
        data: { subscriptionTier: newTier },
      });
      console.log(`[RevenueCat] Updated user ${user.id} tier to ${newTier}`);
    }

    res.status(200).json({ message: 'OK' });
  } catch (err) {
    console.error('[RevenueCat] Webhook error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;

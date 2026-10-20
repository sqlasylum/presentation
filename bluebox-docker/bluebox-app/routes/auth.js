const express = require('express');
const router  = express.Router();
const db      = require('../db');

// ── Login page ───────────────────────────────────────────────────────────────
router.get('/login', (req, res) => {
  if (req.session.user) return res.redirect(req.query.redirect || '/');
  res.render('login', { error: null, redirect: req.query.redirect || '/' });
});

// ── Login submit ─────────────────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  const { full_name, email, redirect } = req.body;
  const next = redirect || '/';

  if (!full_name || !email || !email.includes('@')) {
    return res.render('login', {
      error: 'Please enter your full name and a valid email address.',
      redirect: next,
    });
  }

  try {
    // Look up by email (case-insensitive)
    let result = await db.query(
      `SELECT customer_id, full_name, email, store_id
       FROM bluebox.customer
       WHERE lower(email) = lower($1)
       LIMIT 1`,
      [email.trim()]
    );

    let customer = result.rows[0];

    if (!customer) {
      // customer_id has no sequence — generate next value manually.
      // Wrapped in a transaction to reduce (but not eliminate) race conditions
      // in a demo context where concurrent sign-ups are rare.
      const storeRow = await db.query(
        'SELECT store_id FROM bluebox.store ORDER BY random() LIMIT 1'
      );
      const store_id = storeRow.rows[0]?.store_id || 1;

      const ins = await db.query(
        `INSERT INTO bluebox.customer (customer_id, store_id, full_name, email, activebool, create_date)
         SELECT COALESCE(MAX(customer_id), 0) + 1, $1, $2, $3, true, CURRENT_DATE
         FROM bluebox.customer
         RETURNING customer_id, full_name, email, store_id`,
        [store_id, full_name.trim(), email.trim().toLowerCase()]
      );
      customer = ins.rows[0];
    }

    req.session.user = {
      customer_id: customer.customer_id,
      full_name:   customer.full_name,
      email:       customer.email,
      store_id:    customer.store_id,
    };

    res.redirect(next);
  } catch (err) {
    console.error('login:', err.message);
    res.render('login', { error: 'Login failed. Please try again.', redirect: next });
  }
});

// ── Logout ───────────────────────────────────────────────────────────────────
router.post('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/'));
});

module.exports = router;

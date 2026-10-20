const express = require('express');
const router  = express.Router();
const db      = require('../db');

// ── View cart ────────────────────────────────────────────────────────────────
router.get('/', (req, res) => {
  res.render('cart', { cart: req.session.cart || [] });
});

// ── Add to cart ───────────────────────────────────────────────────────────────
router.post('/add', (req, res) => {
  const { film_id, title, rating } = req.body;
  if (!req.session.cart) req.session.cart = [];

  const id = parseInt(film_id);
  if (id && !req.session.cart.some(item => item.film_id === id)) {
    req.session.cart.push({ film_id: id, title, rating });
  }

  res.redirect(req.headers.referer || '/');
});

// ── Remove from cart ──────────────────────────────────────────────────────────
router.post('/remove', (req, res) => {
  const id = parseInt(req.body.film_id);
  req.session.cart = (req.session.cart || []).filter(item => item.film_id !== id);
  res.redirect('/cart');
});

// ── Checkout ──────────────────────────────────────────────────────────────────
router.post('/checkout', async (req, res) => {
  if (!req.session.user) {
    return res.redirect('/auth/login?redirect=/cart');
  }

  const cart = req.session.cart || [];
  if (cart.length === 0) return res.redirect('/cart');

  const { customer_id, store_id } = req.session.user;
  const rentedFilms = [];
  const failedFilms = [];

  const client = await db.connect();
  try {
    await client.query('BEGIN');

    for (const item of cart) {
      // Find available inventory, prefer the customer's home store
      const inv = await client.query(`
        SELECT i.inventory_id, i.store_id
        FROM bluebox.inventory i
        WHERE i.film_id = $1
          AND i.status_id = 1
          AND NOT EXISTS (
            SELECT 1 FROM bluebox.rental r
            WHERE r.inventory_id = i.inventory_id
              AND upper(r.rental_period) IS NULL
          )
        ORDER BY (i.store_id = $2)::int DESC, random()
        LIMIT 1
        FOR UPDATE SKIP LOCKED
      `, [item.film_id, store_id]);

      if (inv.rows.length === 0) {
        failedFilms.push(item.title);
        continue;
      }

      const { inventory_id, store_id: rental_store_id } = inv.rows[0];

      const rental = await client.query(`
        INSERT INTO bluebox.rental (rental_period, inventory_id, customer_id, store_id)
        VALUES (tstzrange(now(), NULL), $1, $2, $3)
        RETURNING rental_id
      `, [inventory_id, customer_id, rental_store_id]);

      rentedFilms.push({
        ...item,
        rental_id: rental.rows[0].rental_id,
      });
    }

    await client.query('COMMIT');
    req.session.cart = [];
    res.render('checkout-confirm', { rentedFilms, failedFilms });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('checkout:', err.message);
    res.render('error', { message: 'Checkout failed. Please try again.' });
  } finally {
    client.release();
  }
});

module.exports = router;

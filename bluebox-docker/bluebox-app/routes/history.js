const express = require('express');
const router  = express.Router();
const db      = require('../db');

router.get('/', async (req, res) => {
  if (!req.session.user) {
    return res.redirect('/auth/login?redirect=/history');
  }

  const { customer_id } = req.session.user;

  try {
    const [historyResult, statsResult] = await Promise.all([
      db.query(`
        SELECT
          r.rental_id,
          f.film_id,
          f.title,
          f.rating,
          lower(r.rental_period)  AS rented_at,
          upper(r.rental_period)  AS returned_at,
          p.amount,
          s.street_name           AS store_name,
          z.city                  AS store_city,
          z.state_id              AS store_state,
          upper(r.rental_period) IS NULL AS is_open
        FROM bluebox.rental r
        JOIN bluebox.inventory i USING (inventory_id)
        JOIN bluebox.film      f USING (film_id)
        LEFT JOIN bluebox.payment p   ON p.rental_id   = r.rental_id
        LEFT JOIN bluebox.store   s   ON s.store_id    = r.store_id
        LEFT JOIN bluebox.zip_code_info z ON z.zip_code = s.zip_code
        WHERE r.customer_id = $1
        ORDER BY lower(r.rental_period) DESC
        LIMIT 100
      `, [customer_id]),

      db.query(`
        SELECT
          COUNT(*)                                              AS total_rentals,
          COUNT(*) FILTER (WHERE upper(rental_period) IS NULL) AS open_rentals,
          COUNT(*) FILTER (WHERE upper(rental_period) IS NOT NULL) AS completed_rentals,
          COALESCE(SUM(p.amount), 0)                           AS total_spent
        FROM bluebox.rental r
        LEFT JOIN bluebox.payment p ON p.rental_id = r.rental_id
        WHERE r.customer_id = $1
      `, [customer_id]),
    ]);

    res.render('history', {
      rentals: historyResult.rows,
      stats:   statsResult.rows[0],
    });
  } catch (err) {
    console.error('history:', err.message);
    res.render('error', { message: 'Failed to load rental history.' });
  }
});

module.exports = router;

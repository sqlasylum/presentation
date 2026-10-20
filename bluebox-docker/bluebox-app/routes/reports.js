const express = require('express');
const router  = express.Router();
const db      = require('../db');

const REPORTS = {
  status_summary: {
    label:   'Customer Status',
    columns: ['status', 'customer_count', 'pct_of_total', 'avg_lifetime_rentals', 'avg_lifetime_value'],
    sql:     () => db.query('SELECT * FROM bluebox.get_customer_status_summary()'),
  },
  inventory_balance: {
    label:   'Inventory Balance',
    columns: ['store_id', 'nearby_customers', 'current_inventory', 'target_inventory', 'variance', 'variance_pct'],
    sql:     () => db.query('SELECT * FROM bluebox.get_inventory_balance_report()'),
  },
  overdue_rentals: {
    label:   'Overdue Rentals',
    columns: ['rental_id', 'customer_name', 'film_title', 'rental_start', 'days_overdue', 'replacement_cost'],
    sql:     (p) => db.query('SELECT * FROM bluebox.get_overdue_rentals($1)', [p.overdue_days]),
  },
  film_availability: {
    label:   'Film Availability',
    columns: ['title', 'release_date', 'popularity', 'stores_with_film', 'total_copies', 'copies_available'],
    sql:     (p) => db.query(
      'SELECT * FROM bluebox.get_film_availability($1) ORDER BY popularity DESC NULLS LAST LIMIT 100',
      [p.min_stores]
    ),
  },
  inventory_status: {
    label:   'Inventory Status',
    columns: ['status_code', 'description', 'inventory_count', 'pct_of_total'],
    sql:     () => db.query('SELECT * FROM bluebox.get_inventory_status_summary()'),
  },
};

router.get('/', async (req, res) => {
  if (!req.session.user) {
    return res.redirect('/auth/login?redirect=/reports');
  }

  const report      = REPORTS[req.query.report] ? req.query.report : 'status_summary';
  const overdue_days = Math.max(1, parseInt(req.query.overdue_days || '7'));
  const min_stores   = Math.max(0, parseInt(req.query.min_stores  || '0'));
  const def          = REPORTS[report];

  try {
    const result = await def.sql({ overdue_days, min_stores });
    res.render('reports', {
      report,
      reports:      REPORTS,
      data:         result.rows,
      columns:      def.columns,
      overdue_days,
      min_stores,
    });
  } catch (err) {
    console.error('reports:', err.message);
    res.render('error', { message: 'Failed to run report.' });
  }
});

module.exports = router;

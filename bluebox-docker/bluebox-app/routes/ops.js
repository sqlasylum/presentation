const express = require('express');
const router  = express.Router();
const db      = require('../db');
const logger  = require('../services/logger');

// ── Ops dashboard page ───────────────────────────────────────────────────────
router.get('/', (_req, res) => {
  res.render('ops');
});

// Whitelist of allowed chart windows — prevents SQL injection via string interpolation
const WINDOW_CONFIG = {
  '15s': { interval: '15 seconds', trunc: 'second', fmt: 'HH24:MI:SS' },
  '30s': { interval: '30 seconds', trunc: 'second', fmt: 'HH24:MI:SS' },
  '1m':  { interval: '1 minute',   trunc: 'second', fmt: 'HH24:MI:SS' },
  '5m':  { interval: '5 minutes',  trunc: 'minute', fmt: 'HH24:MI'    },
  '30m': { interval: '30 minutes', trunc: 'minute', fmt: 'HH24:MI'    },
  '1d':  { interval: '1 day',      trunc: 'hour',   fmt: 'HH24:MI'    },
  '7d':  { interval: '7 days',     trunc: 'hour',   fmt: 'Dy HH24h'   },
};

// ── SSE stream ───────────────────────────────────────────────────────────────
router.get('/stream', async (req, res) => {
  // Refresh interval: clamped between 1 s and 30 min
  const requestedMs = parseInt(req.query.interval_ms || '5000');
  const intervalMs  = Math.min(Math.max(requestedMs, 1000), 1_800_000);

  // Chart window: validated against whitelist
  const wc = WINDOW_CONFIG[req.query.window] || WINDOW_CONFIG['30m'];

  res.setHeader('Content-Type',  'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection',    'keep-alive');
  res.flushHeaders();

  const send = (data) => {
    res.write(`data: ${JSON.stringify(data)}\n\n`);
  };

  const poll = async () => {
    try {
      const [metrics, activity, trend, topFilms] = await Promise.all([
        db.query(`
          SELECT
            (SELECT count(*) FROM bluebox.rental WHERE upper(rental_period) IS NULL)                           AS open_rentals,
            (SELECT count(*) FROM bluebox.rental WHERE lower(rental_period) > now() - interval '5 minutes')    AS last_5min,
            (SELECT count(*) FROM bluebox.rental WHERE lower(rental_period) > now() - interval '60 minutes')   AS last_hour,
            (SELECT count(*) FROM bluebox.customer WHERE activebool)                                           AS active_customers
        `),

        db.query(`
          SELECT
            r.rental_id,
            f.title,
            c.full_name,
            lower(r.rental_period) AS rented_at
          FROM bluebox.rental r
          JOIN bluebox.inventory i USING (inventory_id)
          JOIN bluebox.film      f USING (film_id)
          JOIN bluebox.customer  c USING (customer_id)
          WHERE lower(r.rental_period) > now() - interval '15 minutes'
          ORDER BY lower(r.rental_period) DESC
          LIMIT 25
        `),

        // Trend query: window and granularity driven by validated wc config
        db.query(`
          SELECT
            to_char(date_trunc('${wc.trunc}', lower(rental_period)), '${wc.fmt}') AS minute,
            count(*) AS rentals
          FROM bluebox.rental
          WHERE lower(rental_period) > now() - interval '${wc.interval}'
          GROUP BY date_trunc('${wc.trunc}', lower(rental_period))
          ORDER BY date_trunc('${wc.trunc}', lower(rental_period))
        `),

        db.query(`
          SELECT f.title, count(*) AS rentals
          FROM bluebox.rental r
          JOIN bluebox.inventory i USING (inventory_id)
          JOIN bluebox.film      f USING (film_id)
          WHERE lower(r.rental_period) > now() - interval '${wc.interval}'
          GROUP BY f.film_id, f.title
          ORDER BY rentals DESC
          LIMIT 8
        `),
      ]);

      send({
        metrics:  metrics.rows[0],
        activity: activity.rows,
        trend:    trend.rows,
        topFilms: topFilms.rows,
        messages: logger.getMessages(),
        ts:       new Date().toISOString(),
      });
    } catch (err) {
      logger.error('poll', err.message);
      console.error('SSE poll error:', err.message);
    }
  };

  await poll();
  const timer = setInterval(poll, intervalMs);
  req.on('close', () => clearInterval(timer));
});

module.exports = router;

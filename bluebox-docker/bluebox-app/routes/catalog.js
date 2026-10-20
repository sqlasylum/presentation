const express = require('express');
const router  = express.Router();
const db      = require('../db');

// ── Catalog / browse ────────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  const q     = (req.query.q || '').trim();
  const genre = (req.query.genre || '').trim();
  const page  = Math.max(1, parseInt(req.query.page || '1'));
  const limit = 24;
  const offset = (page - 1) * limit;

  try {
    const [filmsResult, genresResult, countResult] = await Promise.all([
      db.query(`
        SELECT
          f.film_id,
          f.title,
          f.release_date,
          f.rating,
          f.popularity,
          f.runtime,
          f.overview,
          (SELECT name FROM bluebox.film_genre WHERE genre_id = f.genre_ids[1]) AS primary_genre,
          (SELECT COUNT(*) FROM bluebox.inventory i WHERE i.film_id = f.film_id AND i.status_id = 1) AS available_copies
        FROM bluebox.film f
        WHERE ($1 = '' OR f.fulltext @@ plainto_tsquery('english', $1))
          AND ($2 = '' OR EXISTS (
            SELECT 1 FROM bluebox.film_genre fg
            WHERE fg.genre_id = ANY(f.genre_ids) AND fg.name = $2
          ))
        ORDER BY f.popularity DESC NULLS LAST
        LIMIT $3 OFFSET $4
      `, [q, genre, limit, offset]),

      db.query('SELECT genre_id, name FROM bluebox.film_genre ORDER BY name'),

      db.query(`
        SELECT COUNT(*) AS total
        FROM bluebox.film f
        WHERE ($1 = '' OR f.fulltext @@ plainto_tsquery('english', $1))
          AND ($2 = '' OR EXISTS (
            SELECT 1 FROM bluebox.film_genre fg
            WHERE fg.genre_id = ANY(f.genre_ids) AND fg.name = $2
          ))
      `, [q, genre]),
    ]);

    const total      = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(total / limit);
    const cartFilmIds = (req.session.cart || []).map(item => item.film_id);

    res.render('catalog', {
      films: filmsResult.rows,
      genres: genresResult.rows,
      q, genre,
      page, totalPages, total,
      cartFilmIds,
    });
  } catch (err) {
    console.error('catalog:', err.message);
    res.render('error', { message: 'Failed to load catalog.' });
  }
});

// ── Film detail ──────────────────────────────────────────────────────────────
router.get('/film/:id', async (req, res) => {
  const filmId = parseInt(req.params.id);
  if (!filmId) return res.status(404).render('error', { message: 'Film not found.' });

  try {
    const [filmResult, castResult, crewResult, availResult] = await Promise.all([
      db.query(`
        SELECT f.*,
               ARRAY(SELECT name FROM bluebox.film_genre WHERE genre_id = ANY(f.genre_ids)) AS genres
        FROM bluebox.film f
        WHERE f.film_id = $1
      `, [filmId]),

      db.query(`
        SELECT p.name, fc.film_character
        FROM bluebox.film_cast fc
        JOIN bluebox.person p USING (person_id)
        WHERE fc.film_id = $1
        LIMIT 12
      `, [filmId]),

      db.query(`
        SELECT p.name, fc.job
        FROM bluebox.film_crew fc
        JOIN bluebox.person p USING (person_id)
        WHERE fc.film_id = $1
          AND fc.job IN ('Director','Producer','Screenplay','Writer')
        LIMIT 5
      `, [filmId]),

      db.query(`
        SELECT COUNT(*) AS available
        FROM bluebox.inventory i
        WHERE i.film_id = $1
          AND i.status_id = 1
          AND NOT EXISTS (
            SELECT 1 FROM bluebox.rental r
            WHERE r.inventory_id = i.inventory_id
              AND upper(r.rental_period) IS NULL
          )
      `, [filmId]),
    ]);

    if (!filmResult.rows[0]) {
      return res.status(404).render('error', { message: 'Film not found.' });
    }

    const inCart = (req.session.cart || []).some(item => item.film_id === filmId);

    res.render('film', {
      film: filmResult.rows[0],
      cast: castResult.rows,
      crew: crewResult.rows,
      availableCopies: parseInt(availResult.rows[0].available),
      inCart,
    });
  } catch (err) {
    console.error('film detail:', err.message);
    res.render('error', { message: 'Failed to load film.' });
  }
});

module.exports = router;

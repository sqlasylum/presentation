const express = require('express');
const rateLimit = require('express-rate-limit');
const router = express.Router();
const imageService = require('../services/imageService');
const logger = require('../services/logger');

/**
 * Rate limiter: 1000 requests per day (24 hours)
 * Tracks by IP address
 */
const posterLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000, // 24 hours
  max: 1000, // 1000 requests per day
  message: {
    error: 'Too many poster requests. Limit is 1000 per day.',
    retryAfter: null,
  },
  standardHeaders: true, // Return rate limit info in `RateLimit-*` headers
  legacyHeaders: false, // Disable `X-RateLimit-*` headers
  skip: (req) => {
    // Skip rate limiting for cached images (only limit on cache misses)
    return req.query.skipLimit === 'true';
  },
});

/**
 * GET /api/poster/:filmId/:title
 * Fetch and cache a movie poster image
 * Returns the path to the cached image
 */
router.get('/poster/:filmId/:title', posterLimiter, async (req, res) => {
  try {
    const { filmId, title } = req.params;
    const decodedTitle = decodeURIComponent(title);
    logger.debug('API', `Poster request: ${decodedTitle} (ID: ${filmId})`);
    
    const posterUrl = await imageService.getPosterUrl(
      parseInt(filmId),
      decodedTitle
    );
    
    logger.debug('API', `Poster response: ${decodedTitle} → ${posterUrl}`);
    res.json({ posterUrl });
  } catch (err) {
    logger.error('API', `Error fetching poster: ${err.message}`);
    res.status(500).json({ error: 'Failed to fetch poster', posterUrl: '/posters/placeholder.svg' });
  }
});

module.exports = router;

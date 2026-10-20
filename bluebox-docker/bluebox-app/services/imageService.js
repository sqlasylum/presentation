const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const logger = require('./logger');

const POSTERS_DIR = path.join(__dirname, '../public/posters');

/**
 * Generate an SVG placeholder with the movie title
 * @param {string} title - Movie title to display
 * @returns {string} - SVG content
 */
function generatePlaceholderSVG(title = 'No Poster Available') {
  // Truncate title if too long
  let displayTitle = title;
  if (displayTitle.length > 30) {
    displayTitle = displayTitle.substring(0, 27) + '...';
  }
  
  // Escape XML characters
  displayTitle = displayTitle.replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 450">
    <defs>
      <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" style="stop-color:#2a2a2a;stop-opacity:1" />
        <stop offset="100%" style="stop-color:#1a1a1a;stop-opacity:1" />
      </linearGradient>
    </defs>
    <rect width="300" height="450" fill="url(#grad)"/>
    <rect width="300" height="450" fill="none" stroke="#444" stroke-width="2"/>
    <circle cx="150" cy="180" r="40" fill="#444" opacity="0.3"/>
    <path d="M130 160 L170 160 L170 200 L130 200 Z" fill="#555" opacity="0.3"/>
    <text x="150" y="280" text-anchor="middle" dy=".3em" fill="#999" font-size="14" font-family="Arial, sans-serif" font-weight="bold">
      ${displayTitle}
    </text>
    <text x="150" y="330" text-anchor="middle" dy=".3em" fill="#666" font-size="12" font-family="Arial, sans-serif">
      Click to view details
    </text>
  </svg>`;
}

/**
 * Downloads and caches a movie poster image
 * @param {number} filmId - The film ID
 * @param {string} title - The film title
 * @returns {Promise<string>} - Returns the relative path to the cached image
 */
async function downloadAndCacheImage(filmId, title) {
  // Check if already cached
  const cachedPath = path.join(POSTERS_DIR, `${filmId}.jpg`);
  const cachedSVGPath = path.join(POSTERS_DIR, `${filmId}.svg`);
  
  if (fs.existsSync(cachedPath)) {
    logger.debug('POSTER', `Cache hit: ${title} (${filmId}) → /posters/${filmId}.jpg`);
    return `/posters/${filmId}.jpg`;
  }
  if (fs.existsSync(cachedSVGPath)) {
    logger.debug('POSTER', `Cache hit (SVG): ${title} (${filmId}) → /posters/${filmId}.svg`);
    return `/posters/${filmId}.svg`;
  }

  logger.debug('POSTER', `Cache miss: ${title} (${filmId}) - fetching...`);

  try {
    // Try to fetch from TMDB API if available (skip if empty or only whitespace)
    if (process.env.TMDB_API_KEY && process.env.TMDB_API_KEY.trim()) {
      logger.debug('POSTER', `Attempting TMDB fetch for: ${title}`);
      const posterUrl = await fetchFromTMDB(title);
      if (posterUrl) {
        logger.info('POSTER', `TMDB success for ${title}, downloading...`);
        await downloadImage(posterUrl, cachedPath);
        logger.info('POSTER', `✓ TMDB cached: ${title} (${filmId}) → /posters/${filmId}.jpg`);
        return `/posters/${filmId}.jpg`;
      }
      logger.debug('POSTER', `TMDB no results for: ${title}`);
    }

    // Try to fetch from OMDb API if available (skip if empty or only whitespace)
    if (process.env.OMDB_API_KEY && process.env.OMDB_API_KEY.trim()) {
      logger.debug('POSTER', `Attempting OMDb fetch for: ${title}`);
      const posterUrl = await fetchFromOMDB(title);
      if (posterUrl) {
        logger.info('POSTER', `OMDb success for ${title}, downloading...`);
        await downloadImage(posterUrl, cachedPath);
        logger.info('POSTER', `✓ OMDb cached: ${title} (${filmId}) → /posters/${filmId}.jpg`);
        return `/posters/${filmId}.jpg`;
      }
      logger.debug('POSTER', `OMDb no results for: ${title}`);
    }

    // If no external API worked, use a nice placeholder with the title
    logger.debug('POSTER', `No API results, using SVG placeholder for: ${title}`);
    const placeholderSVG = generatePlaceholderSVG(title);
    fs.writeFileSync(cachedSVGPath, placeholderSVG);
    logger.debug('POSTER', `✓ Placeholder created: ${title} (${filmId}) → /posters/${filmId}.svg`);
    return `/posters/${filmId}.svg`;
  } catch (err) {
    logger.error('POSTER', `✗ Error for ${title} (${filmId}): ${err.message}`);
    // Still return a valid path; the file will be created as placeholder on next request
    return `/posters/placeholder.svg`;
  }
}

/**
 * Fetch poster URL from TMDB API
 * @param {string} title - Movie title to search for
 * @returns {Promise<string|null>} - Poster URL or null
 */
async function fetchFromTMDB(title) {
  return new Promise((resolve) => {
    const searchUrl = `https://api.themoviedb.org/3/search/movie?api_key=${process.env.TMDB_API_KEY}&query=${encodeURIComponent(title)}`;
    
    https.get(searchUrl, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const result = JSON.parse(data);
          if (result.results && result.results[0]?.poster_path) {
            resolve(`https://image.tmdb.org/t/p/w342${result.results[0].poster_path}`);
          } else {
            resolve(null);
          }
        } catch (err) {
          resolve(null);
        }
      });
    }).on('error', () => resolve(null));
  });
}

/**
 * Fetch poster URL from OMDb API
 * @param {string} title - Movie title to search for
 * @returns {Promise<string|null>} - Poster URL or null
 */
async function fetchFromOMDB(title) {
  return new Promise((resolve) => {
    const searchUrl = `http://www.omdbapi.com/?apikey=${process.env.OMDB_API_KEY}&t=${encodeURIComponent(title)}&type=movie`;
    
    http.get(searchUrl, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const result = JSON.parse(data);
          if (result.Poster && result.Poster !== 'N/A') {
            logger.debug('OMDb', `Found poster for "${title}": ${result.Poster}`);
            resolve(result.Poster);
          } else {
            logger.debug('OMDb', `No poster found for "${title}" (Response: ${result.Response}, Poster: ${result.Poster})`);
            resolve(null);
          }
        } catch (err) {
          logger.error('OMDb', `Parse error for "${title}": ${err.message}`);
          resolve(null);
        }
      });
    }).on('error', (err) => {
      logger.error('OMDb', `Network error for "${title}": ${err.message}`);
      resolve(null);
    });
  });
}

/**
 * Download an image from URL and save it locally
 * @param {string} url - Image URL
 * @param {string} filePath - Local file path to save to
 * @returns {Promise<void>}
 */
function downloadImage(url, filePath) {
  return new Promise((resolve, reject) => {
    const protocol = url.startsWith('https') ? https : http;
    logger.debug('DOWNLOAD', `Starting download from: ${url}`);
    
    protocol.get(url, (res) => {
      // Follow redirects
      if (res.statusCode === 301 || res.statusCode === 302) {
        logger.debug('DOWNLOAD', `Redirect to: ${res.headers.location}`);
        return downloadImage(res.headers.location, filePath).then(resolve).catch(reject);
      }
      
      if (res.statusCode !== 200) {
        const err = new Error(`Failed to download image: ${res.statusCode}`);
        logger.error('DOWNLOAD', `✗ ${err.message}`);
        return reject(err);
      }

      const file = fs.createWriteStream(filePath);
      res.pipe(file);
      file.on('finish', () => {
        file.close();
        logger.debug('DOWNLOAD', `✓ Saved to: ${filePath}`);
        resolve();
      });
      file.on('error', (err) => {
        fs.unlink(filePath, () => {}); // Delete partial file
        logger.error('DOWNLOAD', `✗ Write error: ${err.message}`);
        reject(err);
      });
    }).on('error', (err) => {
      logger.error('DOWNLOAD', `✗ Network error: ${err.message}`);
      reject(err);
    });
  });
}

/**
 * Get the URL for a movie poster (with caching)
 * @param {number} filmId - Film ID
 * @param {string} title - Film title
 * @returns {Promise<string>} - Relative path to poster image
 */
async function getPosterUrl(filmId, title) {
  return downloadAndCacheImage(filmId, title);
}

/**
 * Ensure placeholder image exists
 */
function ensurePlaceholder() {
  const placeholderPath = path.join(POSTERS_DIR, 'placeholder.svg');
  if (!fs.existsSync(placeholderPath)) {
    const placeholderSVG = generatePlaceholderSVG();
    fs.writeFileSync(placeholderPath, placeholderSVG);
  }
}

module.exports = {
  getPosterUrl,
  ensurePlaceholder,
  POSTERS_DIR,
};

# Bluebox Movie Poster System

## Overview
The bluebox application now displays movie posters on the catalog page. Posters are fetched from external APIs and cached locally on disk for performance.

## How It Works

1. **On Page Load**: When the catalog page loads, JavaScript fetches poster images for each movie
2. **API Fetch**: The system attempts to fetch posters from configured APIs (TMDB or OMDb)
3. **Local Cache**: Downloaded images are stored in `/public/posters/` for reuse
4. **Fallback**: If no API key is configured or image fetch fails, a placeholder SVG is displayed

## Features

- ✅ Automatic image caching (downloaded once, then reused)
- ✅ No database changes required
- ✅ Responsive image display with proper aspect ratio (2:3 for movie posters)
- ✅ Graceful fallback to placeholder images
- ✅ Optional external API integration
- ✅ Fast loading (cached images are served locally)

## Setup

### Default Setup (No API Key Required)
By default, the system will display placeholder images. No configuration is needed to get started.

```bash
# Start the app - posters will show as placeholders
npm start
```

### Enhanced Setup (With Real Poster Images)

#### Option 1: TMDB API (Recommended - Free Tier Available)

1. Get a free API key:
   - Visit: https://www.themoviedb.org/settings/api
   - Sign up for a free account
   - Generate an API key

2. Add to `.env`:
```
TMDB_API_KEY=your_api_key_here
```

3. Restart the application:
```bash
npm start
```

#### Option 2: OMDb API (Alternative)

1. Get a free API key:
   - Visit: http://www.omdbapi.com/apikey.aspx
   - Register with your email
   - Get a free tier API key

2. Add to `.env`:
```
OMDB_API_KEY=your_api_key_here
```

3. Restart the application

## Files Added/Modified

### New Files
- `services/imageService.js` - Core image fetching and caching logic
- `routes/images.js` - Express route for poster API endpoint
- `public/posters/` - Directory for cached poster images

### Modified Files
- `server.js` - Added image service initialization and route
- `views/catalog.ejs` - Added poster image display to film cards
- `.env` - Added optional API key configuration
- `.gitignore` - Exclude cached poster images from git

## File Structure

```
bluebox-app/
├── public/
│   └── posters/           # Cached poster images (auto-generated)
│       ├── placeholder.svg # Default placeholder
│       ├── 550.jpg        # Cached poster for film_id 550
│       └── 603.jpg        # Cached poster for film_id 603
├── services/
│   └── imageService.js    # Image fetching and caching service
├── routes/
│   └── images.js          # API endpoint for poster fetching
└── views/
    └── catalog.ejs        # Updated with poster display
```

## API Endpoint

The system exposes an internal API endpoint for fetching posters:

```
GET /api/poster/:filmId/:title
```

**Response**:
```json
{
  "posterUrl": "/posters/550.jpg"
}
```

This endpoint:
- Checks if image is already cached
- Fetches from external API if not cached
- Saves to cache
- Returns the cached image path

## Performance

- **First Load**: Images are fetched from external API (1-2 seconds per image)
- **Subsequent Loads**: Images are served from local cache (instant)
- **Memory**: Images are cached on disk, not in memory
- **Network**: Minimized by caching - each image downloaded only once

## Troubleshooting

### No Images Appear
- Check that `.env` file exists in `bluebox-app/`
- If using API key, verify it's correctly configured
- Images default to placeholder SVG if API fails

### API Key Issues
- **TMDB**: Make sure account is verified and API key is enabled
- **OMDb**: Check your email for the API key - may need to activate it
- Test your API key by visiting their service directly

### Cached Images Not Updating
- Delete the `bluebox-app/public/posters/` directory
- Restart the application
- Posters will be re-fetched on next catalog page load

## Future Enhancements

Possible improvements:
- Pre-caching popular movies on application startup
- Image resize/optimization on download
- SVG placeholders with movie titles
- Multiple fallback API sources
- User-uploaded custom posters
- Image quality settings

## API Documentation

See the [TMDB API Docs](https://developers.themoviedb.org/) or [OMDb API Docs](http://www.omdbapi.com/) for more information on the external services used.

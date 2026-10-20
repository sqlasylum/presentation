require('dotenv').config();
const express = require('express');
const session = require('express-session');
const path = require('path');
const imageService = require('./services/imageService');

const app = express();

// View engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Body parsers + static assets
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Initialize image service (ensure placeholder exists)
imageService.ensurePlaceholder();

// Session (MemoryStore is fine for a demo)
app.use(session({
  secret: process.env.SESSION_SECRET || 'bluebox-demo-secret',
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: 24 * 60 * 60 * 1000 }, // 1 day
}));

// Expose user + cart count to every view
app.use((req, res, next) => {
  res.locals.user = req.session.user || null;
  res.locals.cartCount = (req.session.cart || []).length;
  next();
});

// Routes
app.use('/',        require('./routes/catalog'));
app.use('/api',     require('./routes/images'));
app.use('/auth',    require('./routes/auth'));
app.use('/cart',    require('./routes/cart'));
app.use('/history', require('./routes/history'));
app.use('/reports', require('./routes/reports'));
app.use('/ops',     require('./routes/ops'));

// 404
app.use((req, res) => {
  res.status(404).render('error', { message: 'Page not found' });
});

// Error handler
app.use((err, req, res, _next) => {
  console.error(err.stack);
  res.status(500).render('error', { message: 'Something went wrong. Please try again.' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Bluebox app listening on http://0.0.0.0:${PORT}`);
});

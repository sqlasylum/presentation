-- ══════════════════════════════════════════════════════
--  init.sql  —  Demo Shop database
--  Runs once on primary startup
-- ══════════════════════════════════════════════════════

\set ON_ERROR_STOP on

-- ── Create database ──────────────────────────────────
CREATE DATABASE demo_shop;

\c demo_shop

-- ── Tables ───────────────────────────────────────────

CREATE TABLE customers (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL,
    city        VARCHAR(100),
    joined_at   TIMESTAMP DEFAULT NOW()
);

CREATE TABLE products (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    price       NUMERIC(10,2) NOT NULL,
    stock       INT DEFAULT 0,
    category    VARCHAR(50)
);

CREATE TABLE orders (
    id          SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(id),
    product_id  INT REFERENCES products(id),
    quantity    INT NOT NULL DEFAULT 1,
    total       NUMERIC(10,2),
    status      VARCHAR(20) DEFAULT 'pending',
    ordered_at  TIMESTAMP DEFAULT NOW()
);

-- ── Seed data ─────────────────────────────────────────

INSERT INTO customers (name, email, city) VALUES
    ('Alice Johnson',  'alice@example.com',   'New York'),
    ('Bob Smith',      'bob@example.com',     'Los Angeles'),
    ('Carol White',    'carol@example.com',   'Chicago'),
    ('David Brown',    'david@example.com',   'Houston'),
    ('Eve Davis',      'eve@example.com',     'Phoenix'),
    ('Frank Miller',   'frank@example.com',   'Seattle'),
    ('Grace Wilson',   'grace@example.com',   'Boston');

INSERT INTO products (name, price, stock, category) VALUES
    ('Wireless Keyboard',   79.99,  50,  'Electronics'),
    ('USB-C Hub',           49.99, 100,  'Electronics'),
    ('Standing Desk Mat',   39.99,  75,  'Office'),
    ('Mechanical Switches', 24.99, 200,  'Electronics'),
    ('Coffee Mug',          14.99, 150,  'Kitchen'),
    ('Notebook (3-pack)',   12.99, 300,  'Office'),
    ('Monitor Stand',       89.99,  30,  'Office');

INSERT INTO orders (customer_id, product_id, quantity, total, status) VALUES
    (1, 1, 1,  79.99, 'completed'),
    (2, 3, 2,  79.98, 'completed'),
    (3, 6, 1,  12.99, 'shipped'),
    (1, 2, 1,  49.99, 'pending'),
    (4, 5, 3,  44.97, 'completed'),
    (5, 7, 1,  89.99, 'shipped'),
    (6, 4, 2,  49.98, 'processing'),
    (7, 1, 1,  79.99, 'completed'),
    (2, 5, 2,  29.98, 'pending'),
    (3, 2, 1,  49.99, 'completed');

-- ── Quick verification ───────────────────────────────
\echo ''
\echo '=== demo_shop created ==='
SELECT 'customers' AS "table", COUNT(*) FROM customers
UNION ALL
SELECT 'products',              COUNT(*) FROM products
UNION ALL
SELECT 'orders',                COUNT(*) FROM orders;
\echo ''

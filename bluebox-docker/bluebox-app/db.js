const fs = require('fs');
const { Pool } = require('pg');

function resolveHost(hostValue) {
  const host = hostValue || 'localhost';
  const runningInDocker = fs.existsSync('/.dockerenv');

  if (runningInDocker && (host === 'localhost' || host === '127.0.0.1' || host === '::1')) {
    return 'host.docker.internal';
  }

  return host;
}

// Support DATABASE_URL (Heroku/RDS style) or individual PG* env vars
const config = process.env.DATABASE_URL
  ? { connectionString: process.env.DATABASE_URL }
  : {
      host:     resolveHost(process.env.PGHOST),
      port:     parseInt(process.env.PGPORT || '5432'),
      database: process.env.PGDATABASE || 'bluebox',
      user:     process.env.PGUSER     || 'bb_app',
      password: process.env.PGPASSWORD || 'app_password',
    };

const pool = new Pool({
  ...config,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  console.error('Idle client error:', err.message);
  // ops route picks this up via its own error log
});

module.exports = pool;

const { Pool } = require('pg');
require('dotenv').config();

// Render (Cloud) ላይ DATABASE_URL ካለ እሱን ይጠቀማል፤ ካልኖረ Local Variables ይጠቀማል
const pool = new Pool(
  process.env.DATABASE_URL
    ? {
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false }, // Render PostgreSQL SSL ይፈልጋል
      }
    : {
        user: process.env.DB_USER,
        host: process.env.DB_HOST,
        database: process.env.DB_NAME,
        password: process.env.DB_PASSWORD,
        port: process.env.DB_PORT,
      }
);

pool.on('connect', () => {
  console.log('Connected to PostgreSQL Database successfully!');
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

module.exports = pool;
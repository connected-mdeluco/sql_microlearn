const pgp = require('pg-promise')({ capSQL: true });

const db = pgp({
  host: process.env.pg_host,
  port: process.env.pg_port,
  database: process.env.pg_database
});

module.exports = db;

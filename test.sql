SELECT '_' || md5(random()::text) AS db_name;
\gset
\i database.sql

CREATE EXTENSION IF NOT EXISTS pgtap;

\i auth/test.sql

SELECT * FROM runtests();

\c template1
DROP DATABASE :db_name;
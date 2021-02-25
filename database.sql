CREATE DATABASE :db_name;
\c :db_name

CREATE EXTENSION pgcrypto;

\i auth/auth.sql

SELECT current_setting('search_path') AS microlearn_dev_search_path;
\gset
ALTER DATABASE :db_name SET search_path TO :microlearn_dev_search_path;
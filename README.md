# SQL Microlearn
A demonstration of [PostgreSQL](https://www.postgresql.org), [JSON](https://www.postgresql.org/docs/13/functions-json.html),
and [pgTAP](https://pgtap.org) with a Node/Express app.

## Requirements
* [Node.js](https://nodejs.org/en/)
* [Docker](https://www.docker.com)
* [Postman](https://www.postman.com)

## "Quick" Start
To start, open a terminal and follow the commands below.
* Clone the project
* Install npm dependencies
* Build the docker containers
* Connect to the database, test it, and load it

Note that the backend app container exposes port 3000 and will not run
if that port is already bound (to a different running Node/Express app, for example.)

```
$ git clone git@github.com:connected-mdeluco/sql_microlearn.git
...
$ cd sql_microlearn
$ npm install
...
$ COMPOSE_PROJECT_NAME=sql_microlearn && docker-compose up --build -d
...
$ docker exec -it -w /app sql_microlearn_database_1 psql -U microlearner microlearner
psql (12.6 (Ubuntu 12.6-0ubuntu0.20.10.1))
Type "help" for help.

microlearner=# -- Try running the test suite
microlearner=# \i test.sql
...
microlearner=# -- Set a database name variable on the session
microlearner=# \set db_name sql_microlearn
microlearner=# -- Build the database
microlearner=# \i database.sql
...
microlearner=# -- The database is now available for the app
```

Open Postman and import the collection and environment found in `misc/`.

Making sure you've selected the `Microlearn App` environment, experiment with the API:
* Create a record with `POST create authorized email`
* Verify the record exists with `GET get list of authorized emails`
* Authorize a record with `PUT authorize an email`
* Remove a record with `DEL remove email`

## PostgreSQL
[PostgreSQL.org](https://www.postgresql.org)
> "PostgreSQL: The World's Most Advanced Open Source Relational Database"

### JSON
PostgreSQL features functions and operators for querying and working with JSON.

This project focuses on using those tools to build a "CRUD" API on the database itself
to which a frontend application could pass JSON directly, leaving the backend webserver
to handling things like authentication and session management, acting as an HTTP proxy
to the database.

While perhaps not practical from the perspective of some, it's an interesting experiment
to learn and take advantage of these features in Postgre; an opportunity to do things different.

See [examples](#examples) below for a few queries that demonstrate the JSON functions and
operators used most in this project.

### Database Model Notes
Notice that any functions involving cryptography are necessarily slow - bcrypt with 12 iterations
is a time consuming process by design. Read more [about bcrypt](https://en.wikipedia.org/wiki/Bcrypt) (Wikipedia).

## pgTAP
[pgTAP.org](https://pgtap.org)
> "pgTAP is a suite of database functions that make it easy to write TAP-emitting unit tests in psql scripts or xUnit-style test functions."

pgTAP is a very useful tool for unit testing database models, configuration, permissions, modules, and more.
It enables the type of rapid iteration common in other areas of software development that take advantage of
unit and integration testing.

## Postman
A Postman collection and environment configuration are included that may be used to interact
with the webserver:
* [misc/"Microlearn App.postman_collection.json](misc/)
* [misc/"Microlearn App.postman_environment.json"](misc/)

## Examples
Reference:
* [JSON Functions](https://www.postgresql.org/docs/13/functions-json.html)
* [Aggregate Functions](https://www.postgresql.org/docs/13/functions-aggregate.html)
* [WITH Queries](https://www.postgresql.org/docs/9.1/queries-with.html) (not used below)

### API
This is a demonstration of the database JSON CRUD API built in the microlearn.
```
$ cd sql_microlearn
$ psql
# \set db_name sql_microlearn
# \i database.sql

# -- Using JSON, add two records to the auth table
# SELECT * FROM auth.create('[{"email": "cosmo@example.com", "password": "setec astronomy"}, {"email": "bishop@example.com", "password": "fort red border"}]'::JSON);
              create              
----------------------------------
 [{"email":"cosmo@example.com"}, +
  {"email":"bishop@example.com"}]
(1 row)

# -- Query a table as a JSON array of objects
# SELECT json_agg(a) FROM auth a;
                                                  json_agg                                                  
------------------------------------------------------------------------------------------------------------
 [{"email":"cosmo@example.com","password":"$2a$12$fai/78em5vGBDQSb.G1lZus4OFEMRktzGastd.pEQJJp4LiQv53Ze"}, +
  {"email":"bishop@example.com","password":"$2a$12$E7j7WXadFvFpLCIVzgWCAuYVLq/R8zte6sKKPIs0XSzH2MXzrMVv."}]
(1 row)

# -- Query specific columns (for an alternative using CTEs, see auth.get_json() in auth.sql)
# SELECT json_agg(json_build_object('email', a.email)) FROM auth a;
                              json_agg                               
---------------------------------------------------------------------
 [{"email" : "cosmo@example.com"}, {"email" : "bishop@example.com"}]
(1 row)

# -- Authenticate a record
# SELECT * FROM auth.authenticate('{"email": "cosmo@example.com", "password": "setec astronomy"}'::JSON);
     authenticate      
-----------------------
 {"authenticate":true}
(1 row)

# -- Retrieve all records
# SELECT * FROM auth.get_json();
             out_json             
----------------------------------
 [{"email":"cosmo@example.com"}, +
  {"email":"bishop@example.com"}]
(1 row)

# -- Retrieve a specific record
# SELECT * FROM auth.get_json('{"email": "bishop@example.com"}'::JSON);
             out_json             
----------------------------------
 [{"email":"bishop@example.com"}]
(1 row)

# -- Update a record
# SELECT * FROM auth.create_or_update('{"email": "bishop@example.com", "password": "robert redford", "old_password": "fort red border"}'::JSON);   
         create_or_update         
----------------------------------
 [{"email":"bishop@example.com"}]
(1 row)

# -- Authenticate the updated record
# SELECT * FROM auth.authenticate('{"email": "bishop@example.com", "password": "robert redford"}'::JSON);
     authenticate      
-----------------------
 {"authenticate":true}
(1 row)

# -- Remove a record
# -- Note the JSON array, this function takes one or more records to be removed
# SELECT auth.remove('[{"email": "bishop@example.com", "password": "robert redford"}]'::JSON);
              remove              
----------------------------------
 [{"email":"bishop@example.com"}]
(1 row)

# -- Remove a record (incorrect password)
# -- Returns no records, i.e. no records removed
# SELECT auth.remove('[{"email": "cosmo@example.com", "password": "xyzzy"}]'::JSON);
 remove 
--------
 
(1 row)

#
```

### JSON
These are general examples demonstrating the use of PostgreSQL JSON functions and operators.

```
$ psql

# -- Query a JSON array of objects
# SELECT * FROM json_populate_recordset(NULL::auth.auth, '[{"email": "whistler@example.com", "password": "ad variant thirds"}]'::JSON);
        email         |     password      
----------------------+-------------------
 whistler@example.com | ad variant thirds
(1 row)

# -- Same as above, but missing a property
# SELECT * FROM json_populate_recordset(NULL::auth.auth, '[{"email": "whistler@example.com"}]'::JSON);
        email         | password 
----------------------+----------
 whistler@example.com | 
(1 row)

# -- Similar as above, but defining the composite type
# SELECT * FROM json_to_recordset('[{"email": "whistler@example.com", "password": "ad variant thirds"}]'::JSON) AS x(email TEXT, password TEXT);
        email         |     password      
----------------------+-------------------
 whistler@example.com | ad variant thirds
(1 row)

# -- Retrieve a specific property from a JSON object
# SELECT '{"email": "whistler@example.com", "password": "ad variant thirds"}'::JSON->>'email' AS email;
        email         
----------------------
 whistler@example.com
(1 row)

# -- Retrieve a value at a given "path" including array indices and object property keys
# SELECT '[{"email": "whistler@example.com", "password": "ad variant thirds"}]'::JSON#>>'{0, email}' AS email;
        email         
----------------------
 whistler@example.com
(1 row)

# -- Check if the first contains the second
# -- Useful for validating JSON results in pgTAP tests
# SELECT '{"email": "whistler@example.com"}'::JSONB @> '{"email": "whistler@example.com", "password": "ad variant thirds"}'::JSONB AS first_contains_second;
 first_contains_second 
-----------------------
 f
(1 row)

# -- Check if the second contains the first
# SELECT '{"email": "whistler@example.com"}'::JSONB <@ '{"email": "whistler@example.com", "password": "ad variant thirds"}'::JSONB AS second_contains_first;
 second_contains_first 
-----------------------
 t
(1 row)

#
```

## Notes
### REST API
The REST API defined by the backend webserver does not necessarily conform to REST API best practices.
The intent of this project is more to demonstrate the database API.
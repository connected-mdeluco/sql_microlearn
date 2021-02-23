CREATE SCHEMA IF NOT EXISTS auth;
SELECT set_config('search_path', 'auth, ' || current_setting('search_path'), FALSE);

CREATE TABLE IF NOT EXISTS auth.auth (
    email TEXT PRIMARY KEY,
    password TEXT
);

CREATE OR REPLACE FUNCTION auth.hash_password_trigger()
RETURNS TRIGGER AS
$$
BEGIN
    NEW.password := crypt(NEW.password, gen_salt('bf', 12));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER hash_password
    BEFORE INSERT OR UPDATE OF password
    ON auth.auth
    FOR EACH ROW
    EXECUTE FUNCTION auth.hash_password_trigger();

----
-- API
----

CREATE OR REPLACE FUNCTION auth.create_or_update(
    in_email TEXT,
    in_password TEXT,
    in_old_password TEXT = NULL
) RETURNS BOOLEAN AS
$$
BEGIN
    INSERT INTO auth.auth
        VALUES (in_email, in_password)
        ON CONFLICT (email) DO UPDATE
                SET password=in_password
                WHERE (auth.auth.password=crypt(in_old_password, auth.auth.password));
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION auth.authenticate(
    in_email TEXT,
    in_password TEXT
) RETURNS BOOLEAN AS
$$
BEGIN
    PERFORM email FROM auth.auth WHERE email=in_email AND password=crypt(in_password, password);
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION auth.remove(
    in_email TEXT,
    in_password TEXT
) RETURNS TEXT AS
$$
DECLARE
    result TEXT;
BEGIN
    DELETE FROM auth.auth
        WHERE email=in_email
        AND password=crypt(in_password, password)
        RETURNING email INTO result;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION auth.get(
    in_email TEXT = NULL
) RETURNS TABLE(email TEXT) AS
$$
DECLARE
    where_partial_query TEXT := '';
BEGIN
    IF in_email IS NOT NULL THEN
        where_partial_query :=  format('WHERE email=%L', in_email);
    END IF;

    RETURN QUERY EXECUTE(
        'SELECT email FROM auth.auth '
        || where_partial_query
        || ' ORDER BY email DESC');
END;
$$ LANGUAGE plpgsql;

----
-- JSON API
----

CREATE OR REPLACE FUNCTION auth.create_or_update(
    in_json JSON
) RETURNS JSON AS
$$
    WITH records AS (
        INSERT INTO auth.auth (email, password)
        VALUES (in_json->>'email', in_json->>'password')
        ON CONFLICT (email) DO UPDATE
            SET password=in_json->>'password'
            WHERE (auth.auth.password=crypt(in_json->>'old_password', auth.auth.password))
        RETURNING email
    ) SELECT json_agg(r) FROM records r;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION auth.create(in_json JSON)
RETURNS JSON AS
$$
    WITH records AS (
        INSERT INTO auth.auth (email, password)
        SELECT x.email, x.password FROM json_to_recordset(in_json) AS x(email TEXT, password TEXT)
        RETURNING email
    ) SELECT json_agg(r) FROM records r;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION auth.authenticate(in_json JSON)
RETURNS JSON AS
$$
    WITH records AS (
        SELECT password=crypt(in_json->>'password', password) AS authenticate
        FROM auth.auth
        WHERE email=in_json->>'email'
    ) SELECT to_json(r) FROM records r;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION auth.get_json(
    IN in_json JSON = NULL,
    OUT out_json JSON
) RETURNS JSON AS $$
DECLARE
    where_partial_query TEXT := CASE
        WHEN in_json IS NOT NULL THEN
            format('WHERE email=%L', in_json->>'email')
        ELSE
            ''
    END;
BEGIN
    EXECUTE format($query$
        WITH records AS (
            SELECT email FROM auth.auth a %s
        ) SELECT json_agg(r) FROM records r
    $query$, where_partial_query
    ) INTO out_json;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION auth.remove(
    in_json JSON
) RETURNS JSON AS
$$
    WITH records AS (
        DELETE FROM auth.auth
        WHERE email IN (
            SELECT r.email
            FROM json_populate_recordset(NULL::auth.auth, in_json) r
            JOIN auth.auth a
                ON (a.email = r.email AND a.password=crypt(r.password, a.password))
        ) RETURNING email
    ) SELECT json_agg(r) FROM records r;
$$ LANGUAGE sql;

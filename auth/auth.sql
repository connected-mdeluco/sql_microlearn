CREATE SCHEMA IF NOT EXISTS auth;

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
    in_old_password TEXT = ''
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
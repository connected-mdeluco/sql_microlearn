CREATE OR REPLACE FUNCTION test_auth(
) RETURNS SETOF TEXT AS $$
DECLARE
    _email TEXT := 'foo@example.com';
    plaintext_password TEXT := 'foobar';
    new_plaintext_password TEXT := 'bazquux';
BEGIN
    RETURN QUERY SELECT ok(
        auth.create_or_update(_email, plaintext_password),
        'Created new auth entry'
    );

    RETURN QUERY SELECT isnt(
        password,
        plaintext_password,
        'Stored password is not given password'
    ) FROM auth.auth AS a WHERE a.email=_email;

    RETURN QUERY SELECT ok(
        auth.authenticate(_email, plaintext_password),
        'Can authenticate with plaintext password'
    );

    RETURN QUERY SELECT ok(
        auth.create_or_update(
            _email, new_plaintext_password, plaintext_password
        ),
        'Can change password'
    );

    RETURN QUERY SELECT ok(
        auth.authenticate(_email, new_plaintext_password),
        'Can authenticate with changed (new) plaintext password'
    );

    RETURN QUERY SELECT ok(
        NOT auth.authenticate(_email, plaintext_password),
        'Cannot authenticate with old plaintext password'
    );
END;
$$ LANGUAGE plpgsql;
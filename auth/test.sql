CREATE OR REPLACE FUNCTION test_auth(
) RETURNS SETOF TEXT AS $testsuite$
DECLARE
    _email TEXT := 'foo@example.com';
    _alt_email TEXT := 'bar@example.com';
    plaintext_password TEXT := 'foobar';
    new_plaintext_password TEXT := 'bazquux';
BEGIN
    RETURN QUERY SELECT ok(
        auth.create_or_update(_email, plaintext_password),
        'Created new auth entry'
    );

    RETURN QUERY SELECT ok(
        auth.create_or_update(_alt_email, plaintext_password),
        'Created a second auth entry'
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
        NOT auth.authenticate(_email, 'xyzzy'),
        'Cannot authenticate with incorrect password'
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

    RETURN QUERY SELECT results_eq(
        'SELECT auth.get()',
        format($$ VALUES ('%s'), ('%s') $$, _email, _alt_email),
        'Can retrieve auth entries'
    );

    RETURN QUERY SELECT results_eq(
        format($$ SELECT auth.get('%s') $$, _email),
        format($$ VALUES ('%s') $$, _email),
        'Can retrieve a specific auth entry'
    );

    RETURN QUERY SELECT throws_ok(
        auth.remove(_email, 'xyzzy'),
        '22004',
        'query string argument of EXECUTE is null',
        'Cannot remove auth entry with incorrect password'
    );

    RETURN QUERY SELECT is(
        auth.remove(_email, new_plaintext_password),
        _email,
        'Can remove auth entry with correct password'
    );
END;
$testsuite$ LANGUAGE plpgsql;
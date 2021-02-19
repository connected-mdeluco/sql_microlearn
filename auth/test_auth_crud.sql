CREATE OR REPLACE FUNCTION test_auth_crud(
) RETURNS SETOF TEXT AS $testsuite$
DECLARE
    _email TEXT := 'foo@example.com';
    _alt_email TEXT := 'bar@example.com';
    plaintext_password TEXT := 'foobar';
    new_plaintext_password TEXT := 'bazquux';

    payload_json JSON;
    results_json JSON;
    expected_json JSON;
BEGIN

    -- auth.create_or_update()

    -- Create new record
    payload_json = format($$
        {"email": "%s", "password": "%s"}
    $$, _email, plaintext_password);

    results_json = auth.create_or_update(payload_json);
    expected_json = format($$ [{"email": "%s"}] $$, _email);

    RETURN NEXT ok(
        results_json::JSONB @> expected_json::JSONB
        AND results_json::JSONB <@ expected_json::JSONB,
        'Creates a new record'
    );

    RETURN NEXT ok(
        password=crypt(plaintext_password, password),
        'Validates password on new record'
    ) FROM auth.auth WHERE email=_email;

    -- Update record
    payload_json = format($$
        {"email": "%s", "password": "%s", "old_password": "%s"}
    $$, _email, new_plaintext_password, plaintext_password);

    results_json = auth.create_or_update(payload_json);
    expected_json = format($$ [{"email": "%s"}] $$, _email);

    RETURN NEXT ok(
        results_json::JSONB @> expected_json::JSONB
        AND results_json::JSONB <@ expected_json::JSONB,
        'Updates password on record'
    );

    RETURN NEXT ok(
        password=crypt(new_plaintext_password, password),
        'Validates password on updated record'
    ) FROM auth.auth WHERE email=_email;

END;
$testsuite$ LANGUAGE plpgsql;
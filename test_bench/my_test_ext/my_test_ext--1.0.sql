CREATE FUNCTION test_func() RETURNS text AS $$
    SELECT 'version 1.0'::text;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION test_func() RETURNS text AS  $$ /*pg_proc*/
    SELECT 'version 3.0 (from version 1.0)'::text;
$$LANGUAGE SQL;

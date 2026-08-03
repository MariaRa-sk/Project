CREATE OR REPLACE FUNCTION test_func() RETURNS text AS  $$ /*pg_proc*/
    SELECT 'version 2.0'::text;
$$LANGUAGE SQL;


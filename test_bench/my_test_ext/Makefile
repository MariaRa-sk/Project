EXTENSION = my_test_ext

DATA = my_test_ext--1.0.sql \
	my_test_ext--1.0--2.0.sql \
	my_test_ext--1.0--3.0.sql my_test_ext--2.0--3.0.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)


#!/bin/bash

PG_HOME="$HOME/postgres-build"

set -e

if [ -d "${PG_HOME}/primary" ] && [ -f "${PG_HOME}/primary/postgresql.conf" ]; then
	echo "Узел уже существует"

	if pg_ctl -D ${PG_HOME}/primary status >/dev/null 2>&1; then
        	echo "Primary уже работает"
	else
        	echo "Запускаем primary..."
        	pg_ctl -D ${PG_HOME}/primary -l ${PG_HOME}/primary/logfile  start
	fi

	echo "Обновляем настройки на primary..."

	psql -d postgres -c "ALTER SYSTEM SET wal_level = replica;"
	psql -d postgres -c "ALTER SYSTEM SET max_wal_senders = 5;"
	psql -d postgres -c "ALTER SYSTEM SET listen_addresses = 'localhost';"

	pg_ctl -D ${PG_HOME}/primary -l ${PG_HOME}/primary/logfile restart
else
	echo "Узла нет, создаем новый..."
	initdb -D ${PG_HOME}/primary
	echo "Запускаем primary..."
	pg_ctl -D ${PG_HOME}/primary -l ${PG_HOME}/primary/logfile  start
fi

sleep 2

if  [ -d "${PG_HOME}/replica" ]; then

	if pg_ctl -D ${PG_HOME}/replica status >/dev/null 2>&1; then
		echo "Останавливаем старую реплику..."
    		pg_ctl -D ${PG_HOME}/replica stop
	fi

	echo "Удаляем старый каталог replica (не знаем реплика это или нет)..."
	rm -rf ${PG_HOME}/replica
fi

echo "Создаем реплику..."
pg_basebackup -R -X stream -P -h localhost -p 5432 -D ${PG_HOME}/replica
echo "" >> ${PG_HOME}/replica/postgresql.conf
echo "port = 5433" >> ${PG_HOME}/replica/postgresql.conf

echo "Запускаем реплику..."
pg_ctl -D ${PG_HOME}/replica -l ${PG_HOME}/replica/logfile start

echo "Тестовый стенд готов!"

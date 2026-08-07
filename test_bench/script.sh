#!/bin/bash

PG_HOME="$HOME/postgres-build"
PG_SRC="$HOME/postgres-new"

set -e

echo "Собираем постгрес..."
cd $PG_HOME
if [ ! -f "$PG_HOME/Makefile" ]; then
	$PG_SRC/configure --prefix=$PG_HOME/install --enable-debug
fi

make -j16
make install

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

until pg_isready -p 5432 -q 
do
	sleep 1
done

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

#!/bin/bash
set -e

# Ожидание доступности node_b
until pg_isready -h node_b -p 5432 -U postgres; do
    echo "Waiting for node_b to be ready..."
    sleep 2
done

# Создание пользователя для репликации
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator_pass';
EOSQL

# Создание пользователя для администратора Pgpool
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER admin WITH PASSWORD 'admin_pass';
    ALTER USER admin WITH SUPERUSER;
EOSQL


# Создание пользователя для health-чеков
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER healthcheck WITH PASSWORD 'healthcheck_pass';
    GRANT SELECT ON pg_catalog.pg_database TO healthcheck;
EOSQL

# Инициализация репликации
pg_basebackup -h node_b -p 5432 -U replicator -D $PGDATA -Fp -Xs -P -R \
    --application-name=node_c \
    --primary-conninfo="host=node_b port=5432 user=replicator password=replicator_pass application_name=node_c"

# Создание recovery.conf
cat > $PGDATA/recovery.conf << EOF
standby_mode = 'on'
primary_conninfo = 'host=node_b port=5432 user=replicator password=replicator_pass application_name=node_c'
recovery_target_timeline = 'latest'
EOF 

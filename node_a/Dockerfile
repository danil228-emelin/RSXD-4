FROM postgres:15

# Установка дополнительных утилит
RUN apt-get update && apt-get install -y \
    postgresql-contrib \
    && rm -rf /var/lib/apt/lists/*

# Создание директории для WAL архивов
RUN mkdir -p /var/lib/postgresql/wal_archive && \
    chown -R postgres:postgres /var/lib/postgresql/wal_archive

# Копирование скриптов инициализации
COPY scripts/ /docker-entrypoint-initdb.d/
COPY conf/ /etc/postgresql/

# Установка прав
RUN chown -R postgres:postgres /etc/postgresql && \
    chmod +x /docker-entrypoint-initdb.d/*.sh && \
    chown -R postgres:postgres /var/lib/postgresql/data

USER postgres 

FROM postgres:13

LABEL maintainer="David Bitner"

ENV POSTGIS_MAJOR 3

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        jq \
        postgresql-$PG_MAJOR-plpgsql-check \
        postgresql-$PG_MAJOR-pldebugger \
        postgresql-$PG_MAJOR-jsquery \
        postgresql-$PG_MAJOR-pgtap \
        postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
        postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts \
        postgresql-server-dev-$PG_MAJOR \
        build-essential \
        python3 \
        python3-pip \
        python3-setuptools \
        git \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install -U pip setuptools migra[pg]

EXPOSE 5432

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb.sh /docker-entrypoint-initdb.d/10_postgis.sh

WORKDIR /workspaces
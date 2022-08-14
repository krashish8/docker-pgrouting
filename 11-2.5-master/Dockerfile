FROM postgis/postgis:11-2.5

LABEL maintainer="pgRouting Project - https://pgrouting.net"

ENV PGROUTING_VERSION master
ENV PGROUTING_GIT_HASH 

RUN apt update \
 && apt install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        libboost-graph-dev \
        libpq-dev \
        postgresql-server-dev-${PG_MAJOR} \
        git \
 && mkdir -p /usr/src/pgrouting \
 && cd /usr/src/pgrouting \
 && git init \
 && git remote add origin https://github.com/pgRouting/pgrouting.git \
 && git fetch --depth 1 origin :${PGROUTING_GIT_HASH} \
 && git reset --hard FETCH_HEAD \
 && mkdir build \
 && cd build \
 && cmake .. \
 && make \
 && make install \
 && cd / \
 && rm -rf /usr/src/pgrouting \
 && apt purge -y --autoremove \
        build-essential \
        cmake \
        libpq-dev \
        libboost-graph-dev \
        postgresql-server-dev-${PG_MAJOR} \
        git \
 && rm -rf /var/lib/apt/lists/*
RUN rm /docker-entrypoint-initdb.d/10_postgis.sh

COPY ./initdb-pgrouting.sh /docker-entrypoint-initdb.d/pgrouting.sh
COPY ./update-pgrouting.sh /usr/local/bin

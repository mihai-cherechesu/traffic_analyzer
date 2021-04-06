#!/bin/sh

set -e

if [ -n "$CASSANDRA_NODE" ]; then
    ./wait-for "$CASSANDRA_NODE:$CASSANDRA_LISTEN_PORT"
fi

exec "$@"


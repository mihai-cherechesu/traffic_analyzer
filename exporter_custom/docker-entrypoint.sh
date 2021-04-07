#!/bin/sh

set -e

if [ -n "$CASSANDRA_NODE" ]; then
    ./wait-for -t 60 "$CASSANDRA_NODE:$CASSANDRA_LISTEN_PORT"
fi

exec "$@"


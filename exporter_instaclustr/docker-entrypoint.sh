#!/bin/sh

set -e

if [ -n "$JMX_SERVICE_URL" ]; then
    ./wait-for -t 60 "$JMX_SERVICE_URL:$LISTEN_PORT_CASSA"
fi

exec "$@"


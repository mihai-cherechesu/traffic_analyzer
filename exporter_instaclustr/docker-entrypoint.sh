#!/bin/sh

set -e

if [ -n "$JMX_SERVICE_URL" ]; then
    ./wait-for "$JMX_SERVICE_URL:$LISTEN_PORT_CASSA"
fi

exec "$@"


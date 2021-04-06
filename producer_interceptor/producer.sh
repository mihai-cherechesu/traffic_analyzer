#!/bin/sh

base=$(dirname "$0")
while true; do
    curl -s $(shuf -n1 $base/sources) &>/dev/null

    sleep 1
done

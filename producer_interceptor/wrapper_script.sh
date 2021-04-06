#!/usr/bin/env bash

./interceptor.sh 80 &
sleep 2

./producer.sh > /dev/null

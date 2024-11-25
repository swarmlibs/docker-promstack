#!/bin/sh
set -eu

exec /usr/local/bin/docker-entrypoint.sh /promstack.sh "$@"

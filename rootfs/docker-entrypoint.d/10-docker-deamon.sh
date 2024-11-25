#!/bin/sh
# vim:sw=4:ts=4:et

entrypoint_log() {
	if [ -z "${PROMSTACK_ENTRYPOINT_QUIET_LOGS:-}" ]; then
		echo "$@"
	fi
}

ME=$(basename "$0")

test -e "/var/run/docker.sock" || {
	entrypoint_log "$ME: ERROR: Missing docker.sock. You must run the bootstrap container with "-v /var/run/docker.sock:/var/run/docker.sock""
	exit 1
}

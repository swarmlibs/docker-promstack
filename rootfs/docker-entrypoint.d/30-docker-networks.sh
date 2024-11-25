#!/bin/sh
# vim:sw=4:ts=4:et

entrypoint_log() {
	if [ -z "${PROMSTACK_ENTRYPOINT_QUIET_LOGS:-}" ]; then
		echo "$@"
	fi
}

ME=$(basename "$0")

if ! docker network inspect public >/dev/null 2>&1; then
	entrypoint_log "$ME: Creating 'public' network..."
	docker network create --scope=swarm --driver=overlay --attachable public >/dev/null
fi

if ! docker network inspect promstack >/dev/null 2>&1; then
	entrypoint_log "$ME: Creating 'promstack' network..."
	docker network create --scope=swarm --driver=overlay --attachable promstack >/dev/null
fi


if ! docker network inspect prometheus_gwnetwork >/dev/null 2>&1; then
	entrypoint_log "$ME: Creating 'prometheus_gwnetwork' network..."
	docker network create --scope=swarm --driver=overlay --attachable prometheus_gwnetwork >/dev/null
fi

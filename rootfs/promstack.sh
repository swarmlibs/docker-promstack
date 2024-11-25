#!/bin/sh
# vim:sw=4:ts=4:et

entrypoint_log() {
	if [ -z "${PROMSTACK_ENTRYPOINT_QUIET_LOGS:-}" ]; then
		echo "$@"
	fi
}

ME=$(basename "$0")

test -e "/var/run/docker.sock" || {
	entrypoint_log "$ME: ERROR: Missing docker.sock. You must run the bootstrap container with \"-v /var/run/docker.sock:/var/run/docker.sock\""
	exit 1
}

if [[ "${1}" == "install" ]]; then
	PROMSTACK_REPO="https://github.com/swarmlibs/promstack.git"
	PROMSTACK_TMPDIR=`mktemp -d -t promstack-XXXXXX`

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

	entrypoint_log "$ME: Downloading promstack deployment manifest from ${PROMSTACK_REPO}..."
	git clone --quiet --depth 1 ${PROMSTACK_REPO} "${PROMSTACK_TMPDIR}" || {
		entrypoint_log "$ME: ERROR: Failed to clone promstack repository."
		exit 1
	}

	cd "${PROMSTACK_TMPDIR}" && {
		entrypoint_log "$ME: Deploying promstack stack..."
		docker stack deploy --quiet --prune --with-registry-auth --detach=false --compose-file=docker-stack.yml promstack | while read line; do entrypoint_log "$ME: - $line"; done
	}
elif [[ "${1}" == "uninstall" ]]; then
	entrypoint_log "$ME: Attempting to remove the 'promstack' stack..."
	if docker stack ls --format "{{.Name}}" | grep promstack >/dev/null; then
		docker stack rm promstack
	else
		entrypoint_log "$ME: The 'promstack' stack is not deployed."
	fi

	if docker network rm public >/dev/null 2>&1; then
		entrypoint_log "$ME: The 'public' network removed..."
	else
		entrypoint_log "$ME: The 'public' network is not removable. It may be in use by other services."
	fi

	if docker network rm promstack >/dev/null 2>&1; then
		entrypoint_log "$ME: The 'promstack' network removed..."
	else
		entrypoint_log "$ME: The 'promstack' network is not removable. It may be in use by other services."
	fi

	if docker network rm prometheus_gwnetwork >/dev/null 2>&1; then
		entrypoint_log "$ME: The 'prometheus_gwnetwork' network removed..."
	else
		entrypoint_log "$ME: The 'prometheus_gwnetwork' network is not removable. It may be in use by other services."
	fi
else
	entrypoint_log "$ME: Unknown command: ${1}"
	entrypoint_log "$ME: Usage: ${ME} [install|uninstall]"
	exit 1
fi

#!/bin/sh
# vim:sw=4:ts=4:et

entrypoint_log() {
	if [ -z "${PROMSTACK_ENTRYPOINT_QUIET_LOGS:-}" ]; then
		echo "$@"
	fi
}

ME=$(basename "$0")
PROMSTACK_REPO="https://github.com/swarmlibs/promstack.git"
PROMSTACK_TMPDIR=`mktemp -d -t promstack-XXXXXX`

entrypoint_log "$ME: Downloading promstack deployment manifest from ${PROMSTACK_REPO}..."
git clone --quiet --depth 1 ${PROMSTACK_REPO} "${PROMSTACK_TMPDIR}" || {
	entrypoint_log "$ME: ERROR: Failed to clone promstack repository."
	exit 1
}

cd "${PROMSTACK_TMPDIR}" && {
	entrypoint_log "$ME: Deploying promstack stack..."
	docker stack deploy --quiet --prune --with-registry-auth --detach=false --compose-file=docker-stack.yml promstack | while read line; do entrypoint_log "$ME: - $line"; done
}

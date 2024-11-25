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

test -e "/var/run/docker.sock" || {
	entrypoint_log "$ME: ERROR: Missing docker.sock. You must run the bootstrap container with \"-v /var/run/docker.sock:/var/run/docker.sock\""
	exit 1
}

echo '    ____                            __             __  '
echo '   / __ \_________  ____ ___  _____/ /_____ ______/ /__'
echo '  / /_/ / ___/ __ \/ __ `__ \/ ___/ __/ __ `/ ___/ //_/'
echo ' / ____/ /  / /_/ / / / / / (__  ) /_/ /_/ / /__/ ,<   '
echo '/_/   /_/   \____/_/ /_/ /_/____/\__/\__,_/\___/_/|_|  '
echo ''
echo 'A Docker Stack deployment for the monitoring suite for Docker Swarm includes (Grafana, Prometheus, cAdvisor, Node exporter and Blackbox prober exporter)'
echo 'https://github.com/swarmlibs/promstack'
echo ''

if [[ "${1}" == "install" ]]; then
	if ! docker stack ls --format "{{.Name}}" | grep swarmlibs >/dev/null; then
		entrypoint_log "$ME: The 'swarmlibs' stack is not deployed."
		entrypoint_log "$ME: You must deploy the 'swarmlibs' stack otherwise the 'promstack' deployment will not function correctly."
		entrypoint_log "$ME: Please refer to the documentation for more information."
		entrypoint_log "$ME: https://github.com/swarmlibs/swarmlibs"
		entrypoint_log "$ME:"
		entrypoint_log "$ME: Or you can deploy the 'swarmlibs' stack by running the following command:"
		entrypoint_log "$ME: curl -L https://raw.githubusercontent.com/swarmlibs/swarmlibs/main/docker-stack.yml | docker stack deploy -c - swarmlibs"
		entrypoint_log "$ME:"
	fi

	DOCKER_STACK_DEPLOY_ARGS=""
	# If the 'promstack' stack is already deployed, we want to use the --resolve-image=never flag
	if docker stack ls --format "{{.Name}}" | grep promstack >/dev/null; then
		entrypoint_log "$ME: The 'promstack' stack is already deployed, using --resolve-image=never flag to prevent image resolution."
		DOCKER_STACK_DEPLOY_ARGS="--resolve-image=never"
	fi

	entrypoint_log "$ME: Downloading promstack deployment manifest from ${PROMSTACK_REPO}..."
	git clone --quiet --depth 1 ${PROMSTACK_REPO} "${PROMSTACK_TMPDIR}" || {
		entrypoint_log "$ME: ERROR: Failed to clone promstack repository."
		exit 1
	}

	cd "${PROMSTACK_TMPDIR}" && {
		entrypoint_log "$ME: Checking for required networks..."
		if ! docker network inspect public >/dev/null 2>&1; then
			entrypoint_log "$ME: Creating 'public' network..."
			docker network create --scope=swarm --driver=overlay --attachable public >/dev/null
		fi
		if ! docker network inspect prometheus >/dev/null 2>&1; then
			entrypoint_log "$ME: Creating 'prometheus' network..."
			docker network create --scope=swarm --driver=overlay --attachable prometheus >/dev/null
		fi
		if ! docker network inspect prometheus_gwnetwork >/dev/null 2>&1; then
			entrypoint_log "$ME: Creating 'prometheus_gwnetwork' network..."
			docker network create --scope=swarm --driver=overlay --attachable prometheus_gwnetwork >/dev/null
		fi

		entrypoint_log "$ME: Deploying promstack stack..."
		docker stack deploy \
				${DOCKER_STACK_DEPLOY_ARGS} \
				--quiet \
				--with-registry-auth \
				--detach=true \
				--compose-file=docker-stack.yml \
			promstack | while read line; do entrypoint_log "$ME: - $line"; done
		entrypoint_log "$ME:"

		DOCKER_NODE_IP=$(docker node inspect --format '{{.Status.Addr}}' self)
		entrypoint_log "$ME: The deployment is complete, it may take a while for all services to start."
		entrypoint_log "$ME: You can access the services via the following URLs:"
		entrypoint_log "$ME: - Grafana: http://${DOCKER_NODE_IP}:3000"
		entrypoint_log "$ME:     Username: grafana"
		entrypoint_log "$ME:     Password: grafana"
		entrypoint_log "$ME: - Prometheus: http://${DOCKER_NODE_IP}:9090"
	}
elif [[ "${1}" == "upgrade" ]]; then
	if ! docker stack ls --format "{{.Name}}" | grep promstack >/dev/null; then
		entrypoint_log "$ME: The 'promstack' stack is not deployed."
		entrypoint_log "$ME: You must deploy the 'promstack' stack before you can upgrade it."
		exit 1
	fi

	entrypoint_log "$ME: Downloading promstack deployment manifest from ${PROMSTACK_REPO}..."
	git clone --quiet --depth 1 ${PROMSTACK_REPO} "${PROMSTACK_TMPDIR}" || {
		entrypoint_log "$ME: ERROR: Failed to clone promstack repository."
		exit 1
	}

	cd "${PROMSTACK_TMPDIR}" && {
		entrypoint_log "$ME: Upgrading promstack stack..."
		docker stack deploy \
				--quiet \
				--prune \
				--with-registry-auth \
				--detach=true \
				--resolve-image=always \
				--compose-file=docker-stack.yml \
			promstack | while read line; do entrypoint_log "$ME: - $line"; done

		DOCKER_NODE_IP=$(docker node inspect --format '{{.Status.Addr}}' self)
		entrypoint_log "$ME: The upgrade is complete, it may take a while for all services to start."
		entrypoint_log "$ME: You can access the services via the following URLs:"
		entrypoint_log "$ME: - Grafana: http://${DOCKER_NODE_IP}:3000"
		entrypoint_log "$ME: - Prometheus: http://${DOCKER_NODE_IP}:9090"
	}
elif [[ "${1}" == "uninstall" ]]; then
	entrypoint_log "$ME: Attempting to remove the 'promstack' stack..."
	if docker stack ls --format "{{.Name}}" | grep promstack >/dev/null; then
		docker stack rm promstack && {
			echo "$ME: Grace period to allow services to shutdown..."
			sleep 15
		}
	else
		entrypoint_log "$ME: The 'promstack' stack is not deployed."
	fi

	if docker network rm prometheus >/dev/null 2>&1; then
		entrypoint_log "$ME: The 'prometheus' network removed..."
	else
		entrypoint_log "$ME: The 'prometheus' network is not removable. It may be in use by other services."
	fi

	if docker network rm prometheus_gwnetwork >/dev/null 2>&1; then
		entrypoint_log "$ME: The 'prometheus_gwnetwork' network removed..."
	else
		entrypoint_log "$ME: The 'prometheus_gwnetwork' network is not removable. It may be in use by other services."
	fi

	entrypoint_log "$ME:"
	entrypoint_log "$ME: The removal is complete, the 'promstack' stack and associated networks have been removed."
	entrypoint_log "$ME: It may take a while for all services to be completely removed."
else
	entrypoint_log "$ME: Unknown command: ${1}"
	entrypoint_log "$ME: Usage: ${ME} [install|uninstall]"
	exit 1
fi

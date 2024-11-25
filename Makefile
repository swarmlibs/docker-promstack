it:
	docker buildx bake --load

install:
	docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock swarmlibs/promstack:dev

# About
A promstack installer as container image

## Usage

**Install promstack**
```sh
docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock swarmlibs/promstack:dev
```

**Uninstall promstack**
```sh
docker stack rm promstack
```

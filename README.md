# About
An unattended installer for `promstack` stack.

## Usage
The installer provides the following commands:
- `install` - Install the promstack stack.
- `upgrade` - Upgrade the promstack stack.
- `uninstall` - Uninstall the promstack stack.

### Install `promstack` stack
Run the following command to install the promstack stack:
```sh
$ docker run -it --rm \
    --name promstack \
    -v /var/run/docker.sock:/var/run/docker.sock \
    swarmlibs/promstack:dev install
```

### Upgrade `promstack` stack
Run the following command to upgrade the promstack stack:
```sh
$ docker run -it --rm \
    --name promstack \
    -v /var/run/docker.sock:/var/run/docker.sock \
    swarmlibs/promstack:dev upgrade
```

### Uninstall `promstack` stack
Run the following command to uninstall the promstack stack:
```sh
$ docker run -it --rm \
    --name promstack \
    -v /var/run/docker.sock:/var/run/docker.sock \
    swarmlibs/promstack:dev uninstall
```

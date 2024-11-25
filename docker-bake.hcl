target "docker-metadata-action" {}
target "github-metadata-action" {}

target "default" {
    inherits = [
        "docker-metadata-action",
        "github-metadata-action",
    ]
    platforms = [
        "linux/amd64",
        "linux/arm64"
    ]
}

target "dev" {
    tags = [
        "swarmlibs/promstack:dev"
    ]
}

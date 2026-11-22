# common-podman-docker

Makes Podman the only container engine. It removes Docker CE and gives
Docker-only tools what they expect, served by Podman. See the comments in
`recipes/common-podman-docker.yml` for what each piece does.

| Tool expects | What answers |
| --- | --- |
| `docker` command | `podman` (podman-docker shim) |
| `DOCKER_HOST` | Rootless socket at `$XDG_RUNTIME_DIR/podman/podman.sock`, set in login shells, the COSMIC session and systemd user services |
| `/var/run/docker.sock` | Rootful socket at `/run/podman/podman.sock` (root only) |
| `docker compose` | Standalone `docker-compose` against the Podman socket |

Tools that honor `DOCKER_HOST` (VS Code Dev Containers, Testcontainers,
docker-compose, most SDKs) use rootless Podman with no extra setup. A tool
that ignores `DOCKER_HOST` and opens `/var/run/docker.sock` gets the rootful
socket and needs root; point it at the rootless socket in its own settings
instead.

## Moving data from Docker

Rebasing to an image with this module leaves `/var/lib/docker` on disk but
removes the daemon. Images can be pulled again. Named volumes are plain
directories under `/var/lib/docker/volumes/<name>/_data`, so they can be
copied into a Podman volume with or without Docker installed:

```sh
sudo ls /var/lib/docker/volumes

name=monolith-data
podman volume create "$name"
sudo tar -C "/var/lib/docker/volumes/$name/_data" -cf - . \
  | podman run --rm -i -v "$name":/to docker.io/library/alpine tar -C /to -xpf -
```

Unpacking inside a container maps file ownership into rootless Podman's user
namespace, so services that run as a fixed uid (databases, Elasticsearch)
keep working.

When nothing else is needed from Docker, reclaim the space:

```sh
sudo rm -rf /var/lib/docker /var/lib/containerd
```

## Local image builds

Pass `-B podman` to BlueBuild so it builds with Podman directly. See the
validation notes in `AGENTS.md`.

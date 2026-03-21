# `common-hytale.yml`

This module adds the host-level prerequisites for running a dedicated Hytale server on Fedora/ucore-based images.

It installs:

- OpenJDK 25 via `java-25-openjdk-headless`
- `unzip` so the Hytale Downloader CLI archive can be unpacked on-host
- a dedicated `hytale` system user and group
- a tmpfiles definition that pre-creates the writable Hytale runtime directories
- a systemd unit for running the server through the official Hytale launcher script

The Hytale server binaries and assets are intentionally **not** installed by this module. They update more frequently than the OS image and should live on the writable filesystem under `/var/lib/hytale`.

## Files

The module lives at:

- `recipes/common-hytale.yml`

It copies the Hytale support files from:

- `files/hytale/etc/hytale/hytale.env`
- `files/hytale/usr/lib/sysusers.d/hytale.conf`
- `files/hytale/usr/lib/tmpfiles.d/hytale.conf`
- `files/hytale/usr/lib/systemd/system/hytale.service`

## Runtime Layout

The image pre-creates these directories:

- `/var/lib/hytale`
- `/var/lib/hytale/game`
- `/var/lib/hytale/game/Server`

Populate `/var/lib/hytale/game` with the layout expected by the official Hytale updater:

```text
/var/lib/hytale/game/
├── Assets.zip
├── start.sh
├── jvm.options
└── Server/
    ├── HytaleServer.jar
    ├── HytaleServer.aot
    ├── config.json
    ├── permissions.json
    ├── whitelist.json
    ├── bans.json
    ├── logs/
    ├── mods/
    ├── universe/
    └── updater/
```

This matches the official Hytale server layout for update support: the parent `game/` directory contains `Assets.zip` and `start.sh`, while the server itself runs from `Server/`.

## Using The Module

Include it from any recipe that should host a Hytale server:

```yaml
modules:
  - from-file: common-hytale.yml
```

`recipes/recipe-mario.yml` is the machine-specific image for the `mario` host and already includes this module.

## Host Setup On Mario

After rebasing `mario` to the custom image:

1. Confirm Java 25 is available:

   ```console
   java --version
   ```

2. Download and unpack the Hytale Downloader CLI on the host.
3. Use the downloader to place the server files in `/var/lib/hytale/game`.
4. Ensure the writable tree is owned by the service account:

   ```console
   sudo chown -R hytale:hytale /var/lib/hytale
   ```

5. Perform the first launch manually so you can complete device authentication:

   ```console
   sudo -u hytale /usr/libexec/hytale-launcher
   ```

6. At the server console, run `/auth login device` and complete the browser flow.
7. Once authentication succeeds, stop the manual session and enable the service:

   ```console
   sudo systemctl enable --now hytale.service
   ```

The baked systemd unit does not start until `/var/lib/hytale/game/start.sh` exists, so the image can boot cleanly before the downloader has populated the server.

If the downloaded `start.sh` arrives with Windows `CRLF` line endings, the wrapper fixes that automatically before launching it.

## Operations Notes

- The default Hytale server port is `5520/udp`. Open or forward UDP, not TCP.
- Keep JVM tuning in `/var/lib/hytale/game/jvm.options`; the official `start.sh` reads it automatically.
- The official launcher script also handles staged self-updates and preserves config, saves, and mods.
- Hytale recommends monitoring RAM and CPU usage and tuning memory settings with `-Xmx`.
- View distance is a major RAM driver; the official manual recommends limiting maximum view distance to 12 chunks.

## Validation

Recipe changes can be validated locally with:

```console
bluebuild build -v ./recipes/recipe-mario.yml
```

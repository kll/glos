# `common-hytale.yml`

This module adds the host-level prerequisites for running a dedicated Hytale server on Fedora/ucore-based images.

It installs:

- OpenJDK 25 via `java-25-openjdk-headless`
- `unzip` so the Hytale Downloader CLI archive can be unpacked on-host
- a dedicated `hytale` system user and group
- a tmpfiles definition that pre-creates the writable Hytale runtime directories
- a systemd unit for running the server through the official Hytale launcher script
- a FIFO-backed console bridge for sending commands to the running server service
- a firewalld service and boot-time helper that opens Hytale in the host's default firewall zone

The Hytale server binaries and assets are intentionally **not** installed by this module. They update more frequently than the OS image and should live on the writable filesystem under `/var/lib/hytale`.

## Files

The module lives at:

- `recipes/common-hytale.yml`

It copies the Hytale support files from:

- `files/hytale/etc/hytale/hytale.env`
- `files/hytale/usr/lib/firewalld/services/hytale.xml`
- `files/hytale/usr/lib/sysusers.d/hytale.conf`
- `files/hytale/usr/lib/systemd/system/hytale-firewalld.service`
- `files/hytale/usr/lib/tmpfiles.d/hytale.conf`
- `files/hytale/usr/lib/systemd/system/hytale.service`
- `files/hytale/usr/bin/hytale-console`
- `files/hytale/usr/libexec/hytale-firewall-setup`
- `files/hytale/usr/libexec/hytale-launcher`
- `files/hytale/usr/libexec/hytale-service-runner`

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

On firewalld-based hosts, the image also enables `hytale-firewalld.service`, which adds the custom `hytale` firewall service to the host's default zone. That opens `5520/udp` automatically after boot.

## Service Console Access

When `hytale.service` is running, the image provides a FIFO-backed command bridge at `/run/hytale/console.in` and a helper command:

```console
sudo hytale-console '/update status'
sudo hytale-console '/update check'
sudo hytale-console '/say Server restart in 5 minutes'
```

For multi-line input or interactive piping:

```console
printf '/update status\n/update check\n' | sudo hytale-console
```

To watch console output while the service is running:

```console
journalctl -fu hytale.service
```

This is intended for one-shot administrative commands. It does not provide a full terminal attachment like `tmux`, but it does preserve access to server-console commands such as `/update status`, `/update check`, and `/update apply --confirm`.

## Operations Notes

- The default Hytale server port is `5520/udp`. Open or forward UDP, not TCP.
- On hosts using `firewalld`, `common-hytale.yml` opens `5520/udp` automatically in the default zone. If a host uses a non-default zone assignment or another firewall stack, adjust that host manually.
- Keep JVM tuning in `/var/lib/hytale/game/jvm.options`; the official `start.sh` reads it automatically.
- Use `sudo hytale-console '<command>'` to send Hytale console commands to the running systemd service.
- Use `journalctl -fu hytale.service` to follow server console output in real time.
- The official launcher script also handles staged self-updates and preserves config, saves, and mods.
- Hytale recommends monitoring RAM and CPU usage and tuning memory settings with `-Xmx`.
- View distance is a major RAM driver; the official manual recommends limiting maximum view distance to 12 chunks.

## Validation

Recipe changes can be validated locally with:

```console
bluebuild build -v ./recipes/recipe-mario.yml
```

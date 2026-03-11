# `common-android-host.yml`

This module adds the host-level prerequisites for running Android Studio from the upstream Linux tarball on Fedora/Aurora-based images.

It installs:

- `adb` and `fastboot` via `android-tools`
- Fedora compatibility libraries commonly needed by Android Studio on Linux
- OpenJDK 21 for command-line Gradle and other Android CLI tooling
- Android USB udev rules for broad device support
- a `plugdev` sysusers entry so the USB access group exists in the image

Android Studio itself is not installed by this module. The intended flow is still to download the latest Android Studio Linux tarball and extract it under your home directory.

## Files

The module lives at:

- `recipes/common-android-host.yml`

It copies the Android host support files from:

- `files/android-host/usr/lib/udev/rules.d/51-android.rules`
- `files/android-host/usr/lib/sysusers.d/android-host.conf`

## Using The Module

Include it from any recipe that should have Android development host support:

```yaml
modules:
  - from-file: common-android-host.yml
```

## User Setup

Some setup remains user-specific and is intentionally not handled by the image.

For USB debugging:

- make sure your user is in `plugdev`
- re-log or reboot after group membership changes

For Android Emulator acceleration:

- make sure your user is in `kvm`
- confirm `/dev/kvm` is usable on the host

Example:

```console
sudo usermod -aG plugdev,kvm "$USER"
```

After re-logging, useful checks are:

```console
adb version
fastboot --version
java -version
groups
```

## Notes

- The vendored `51-android.rules` file is based on the upstream community-maintained Android udev ruleset.
- The rules are normalized for this repo to use `GROUP="plugdev"` with `TAG+="uaccess"` and `MODE="0660"`.
- The module is reusable and is not tied to a specific machine beyond whichever recipes include it.

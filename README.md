# Gelatinous OS &nbsp; [![bluebuild build badge](https://github.com/kll/glos/actions/workflows/build.yml/badge.svg)](https://github.com/kll/glos/actions/workflows/build.yml)

These are my customized versions of universal blue images for my needs.

## Installation

You can rebase to a **glos** image using the following:
```console
$ sudo bootc switch --enforce-container-sigpolicy ghcr.io/kll/glos-VARIANT:stable
```

Replace VARIANT with the desired variant of the image.

## Verification

All images in this repo are signed with sigstore's cosign. You can verify the signatures by running the following command

```console
$ cosign verify --key "https://raw.githubusercontent.com/kll/glos/refs/heads/main/cosign.pub" "ghcr.io/kll/glos-VARIANT:stable
```
Again replace the VARIANT with the specified image variant
# `common-erlang-build.yml`

This module adds the base native packages needed for source-built Erlang/OTP installs via `mise install erlang`.

It currently installs:

- `ncurses-devel` so OTP's configure step can find curses functions and headers
- `openssl-devel` for OTP's SSL applications and build checks

The goal is to make `mise install erlang` work across the shared desktop base images without pulling in every optional OTP feature dependency.

## Files

The module lives at:

- `recipes/common-erlang-build.yml`

It is included by:

- `recipes/common-aurora.yml`
- `recipes/common-bazzite.yml`

That means all Aurora and Bazzite images built from those shared base recipes inherit these packages.

## Using The Module

Include it from any recipe that should support source-built Erlang/OTP:

```yaml
modules:
  - from-file: common-erlang-build.yml
```

## Notes

- This is intentionally a minimal dependency set.
- Optional OTP features such as `observer`, ODBC, Java integration, or documentation generation may require additional packages later.
- If a future `mise install erlang` failure reports another missing system library during `configure`, that package can be evaluated for addition here.

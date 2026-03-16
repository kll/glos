# `common-erlang-build.yml`

This module adds the base native packages needed for source-built Erlang/OTP installs via `mise install erlang`.

It currently installs:

- `gcc-c++` so OTP's JIT C++ build can find the standard library headers
- `ncurses-devel` so OTP's configure step can find curses functions and headers
- `openssl-devel` for OTP's SSL applications and build checks
- `unixODBC-devel` so OTP can build the `odbc` application
- `wxGTK-devel` so OTP can build `wx` tools such as `observer`
- `mesa-libGL-devel` and `mesa-libGLU-devel` for wx/OpenGL support
- `webkit2gtk4.1-devel` so wx webview support is available when supported by the packaged wx build

The goal is to make `mise install erlang` work across the shared desktop base images with the common optional OTP applications enabled.

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

- This module now includes the common optional dependencies for ODBC and wx-based tooling.
- Java integration and documentation generation are still not enabled by this module.
- If a future `mise install erlang` failure reports another missing system library during `configure`, that package can be evaluated for addition here.

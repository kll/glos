# Repo Notes

- This repo builds BlueBuild images. Most changes belong in `recipes/` and `files/`.
- Reusable image modules live in `recipes/common-*.yml`.
- Machine-specific recipes live in `recipes/recipe-*.yml`.
- Files copied into images live under `files/<name>/` and are usually referenced by a `files` module.
- Keep machine-specific documentation out of `README.md`. Put module or setup docs in `docs/`.

# Validation

- Validate recipe changes locally with `bluebuild build -v ./recipes/<recipe>.yml`.
- If a local build fails during final export/import with `no space left on device`, treat that as a host storage problem unless an earlier module step failed.

# Documentation

- For BlueBuild-specific modules, recipe semantics, and initramfs/dracut behavior, verify against current upstream BlueBuild documentation instead of assuming from memory.

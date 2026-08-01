#!/usr/bin/env bash
set -euo pipefail

mapfile -t installed_kernel_versions < <(
  rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -u
)

if (( ${#installed_kernel_versions[@]} == 0 )); then
  echo "No installed kernel-core package was found" >&2
  exit 1
fi

declare -A installed_kernels=()
for kernel_version in "${installed_kernel_versions[@]}"; do
  installed_kernels["${kernel_version}"]=1
done

shopt -s nullglob
for module_dir in /usr/lib/modules/*; do
  [[ -d "${module_dir}" ]] || continue

  kernel_version="${module_dir##*/}"
  if [[ -n "${installed_kernels[${kernel_version}]:-}" ]]; then
    if [[ ! -f "${module_dir}/modules.dep" ]]; then
      echo "Installed kernel ${kernel_version} has no modules.dep" >&2
      exit 1
    fi
    continue
  fi

  # Refuse to remove anything resembling a complete, unexpected kernel tree.
  if [[ -f "${module_dir}/modules.dep" || -d "${module_dir}/kernel" || -f "${module_dir}/vmlinuz" ]]; then
    echo "Unexpected complete kernel module tree: ${module_dir}" >&2
    exit 1
  fi

  echo "Removing orphaned incomplete kernel module tree: ${module_dir}"
  rm -rf -- "${module_dir}"
done

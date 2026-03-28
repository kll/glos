#!/usr/bin/env bash
set -euo pipefail

KVMFR_REF="7f31ecf5e572ecdfa64306be76e49ee537f5fdbf"
KVMFR_VERSION="0.0.git.${KVMFR_REF:0:8}"
BUILD_ROOT="$(mktemp -d)"
BUILD_DEPS=(
  cpio
  elfutils-libelf-devel
  gcc
  make
)

cleanup() {
  rm -rf "${BUILD_ROOT}"
}

trap cleanup EXIT

KERNEL_VERSION="$(rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | head -n1)"
KERNEL_DEVEL_URL="$(
  dnf5 -q \
    --disablerepo='*' \
    --enablerepo=fedora \
    --enablerepo=updates \
    --enablerepo=updates-archive \
    repoquery --location "kernel-devel-${KERNEL_VERSION}" | head -n1
)"

if [[ -z "${KERNEL_DEVEL_URL}" ]]; then
  echo "Failed to resolve kernel-devel for ${KERNEL_VERSION}" >&2
  exit 1
fi

missing_build_deps=()
for pkg in "${BUILD_DEPS[@]}"; do
  if ! rpm -q "${pkg}" >/dev/null 2>&1; then
    missing_build_deps+=("${pkg}")
  fi
done

if (( ${#missing_build_deps[@]} > 0 )); then
  dnf -y install "${missing_build_deps[@]}"
fi

mkdir -p "${BUILD_ROOT}/kernel-devel" "${BUILD_ROOT}/source"
curl -fsSL "${KERNEL_DEVEL_URL}" -o "${BUILD_ROOT}/kernel-devel.rpm"
rpm2cpio "${BUILD_ROOT}/kernel-devel.rpm" | (
  cd "${BUILD_ROOT}/kernel-devel" && cpio -idmu --quiet
)

curl -fsSL "https://codeload.github.com/gnif/LookingGlass/tar.gz/${KVMFR_REF}" \
  -o "${BUILD_ROOT}/looking-glass.tar.gz"
tar -C "${BUILD_ROOT}/source" -xzf "${BUILD_ROOT}/looking-glass.tar.gz"

MODULE_SOURCE_DIR="${BUILD_ROOT}/source/LookingGlass-${KVMFR_REF}/module"
KERNEL_BUILD_DIR="${BUILD_ROOT}/kernel-devel/usr/src/kernels/${KERNEL_VERSION}"
MODULE_DEST_DIR="/usr/lib/modules/${KERNEL_VERSION}/extra/kvmfr"

find "${MODULE_SOURCE_DIR}" -type f -name '*.c' \
  -exec sed -i "s/#VERSION#/${KVMFR_VERSION}/g" {} +

make -C "${KERNEL_BUILD_DIR}" M="${MODULE_SOURCE_DIR}" VERSION="v${KVMFR_VERSION}" modules

install -d "${MODULE_DEST_DIR}"
install -m 0644 "${MODULE_SOURCE_DIR}/kvmfr.ko" "${MODULE_DEST_DIR}/kvmfr.ko"
depmod -a "${KERNEL_VERSION}"

if (( ${#missing_build_deps[@]} > 0 )); then
  dnf -y remove "${missing_build_deps[@]}"
fi

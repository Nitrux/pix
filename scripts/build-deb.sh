#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024-2025 <Nitrux Latinoamericana S.C. <hello@nxos.org>>


# -- Exit on errors.

set -euo pipefail

# -- Prepare source.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
export PATH="/usr/lib/qt6/bin:$PATH"
PACKAGE_VERSION="${PACKAGE_VERSION:-0.0.1}"
TARGET_ARCH="${TARGET_ARCH:-$(dpkg --print-architecture)}"

# -- Download Source

git clone --depth 1 --branch "${PIX_BRANCH}" https://github.com/Nitrux/maui-pix.git "$repo_root/maui-pix"
source_dir="$repo_root/maui-pix"

# -- Configure build.

build_dir="$repo_root/build"
meson_dir="$build_dir/meson"
stage_dir="$build_dir/package"
rm -rf "$meson_dir" "$stage_dir"
mkdir -p "$build_dir"

meson_args=(--prefix=/usr --buildtype=release)
if [ "$(dpkg-architecture -qDEB_HOST_ARCH)" = "amd64" ]; then
    meson_args+=("-Dcpp_args=-march=x86-64-v3")
fi

# -- Compile Source

meson setup "$meson_dir" "$source_dir" "${meson_args[@]}"
meson compile -C "$meson_dir" -j "$(nproc)"

# -- Install source to DESTDIR.

DESTDIR="$stage_dir" meson install -C "$meson_dir"

# -- Create DEBIAN control file.

mkdir -p "$stage_dir/DEBIAN"
cat > "$stage_dir/DEBIAN/control" <<CONTROL
Package: pix
Version: ${PACKAGE_VERSION}
Section: graphics
Priority: optional
Architecture: ${TARGET_ARCH}
Maintainer: uri_herrera@nxos.org
Provides: pix
Depends: kio-extras,libkexiv2qt6-0,mauikit (>= 4.0.4),mauikit-filebrowsing (>= 4.0.4),mauikit-imagetools (>= 4.0.4),qml6-module-qtcore,qml6-module-qtlocation,qml6-module-qtquick-effects
Description: pix
 pix
CONTROL

# -- Create .deb.

dpkg-deb --build --root-owner-group "$stage_dir" "$build_dir/pix_${PACKAGE_VERSION}_${TARGET_ARCH}.deb"

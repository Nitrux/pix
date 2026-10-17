#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024-2025 <Nitrux Latinoamericana S.C. <hello@nxos.org>>


# -- Exit on errors.

set -euo pipefail

# -- Prepare source.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
export PATH="/usr/lib/qt6/bin:$PATH"
PACKAGE_VERSION="${PACKAGE_VERSION:?PACKAGE_VERSION must be supplied by CI}"
TARGET_ARCH="${TARGET_ARCH:-$(dpkg --print-architecture)}"

# -- Download Source

git clone --depth 1 --branch "${PIX_BRANCH}" https://github.com/Nitrux/maui-pix.git "$repo_root/maui-pix"
source_dir="$repo_root/maui-pix"

# -- Configure build.

# MauiKit software must be built with CMake and ECM; never use Meson.
build_dir="$repo_root/build"
cmake_dir="$build_dir/cmake"
stage_dir="$build_dir/package"
rm -rf "$cmake_dir" "$stage_dir"
mkdir -p "$build_dir"

cmake_args=(
    -DCMAKE_INSTALL_PREFIX=/usr
    -DCMAKE_BUILD_TYPE=Release
)
if [ "$(dpkg-architecture -qDEB_HOST_ARCH)" = "amd64" ]; then
    cmake_args+=("-DCMAKE_CXX_FLAGS=-march=x86-64-v3")
fi

# -- Compile Source

cmake -S "$source_dir" -B "$cmake_dir" "${cmake_args[@]}"
cmake --build "$cmake_dir" --parallel "$(nproc)"

# -- Install source to DESTDIR.

DESTDIR="$stage_dir" cmake --install "$cmake_dir"

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
Depends: qml6-module-qtquick-controls,qml6-module-qtquick-layouts,qml6-module-qtquick-window,libkf6i18n6,libkf6kiocore6,libqt6concurrent6,libqt6core6t64,libqt6dbus6,libqt6gui6,libqt6positioning6,libqt6qml6,libqt6quick6,kio-extras,libkexiv2qt6-0,mauikit (>= 4.0.4),mauikit-filebrowsing (>= 4.0.4),mauikit-imagetools (>= 4.0.4),qml6-module-qtcore,qml6-module-qtlocation,qml6-module-qtquick-effects
Description: pix
 pix
CONTROL

# -- Create .deb.

dpkg-deb --build --root-owner-group "$stage_dir" "$build_dir/pix_${PACKAGE_VERSION}_${TARGET_ARCH}.deb"

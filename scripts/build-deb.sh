#! /bin/bash

set -x

### Update sources

wget -qO /etc/apt/sources.list.d/nitrux-depot.list https://raw.githubusercontent.com/Nitrux/iso-tool/legacy/configs/files/sources/sources.list.nitrux

wget -qO /etc/apt/sources.list.d/nitrux-testing.list https://raw.githubusercontent.com/Nitrux/iso-tool/legacy/configs/files/sources/sources.list.nitrux.testing

curl -L https://packagecloud.io/nitrux/depot/gpgkey | apt-key add -;
curl -L https://packagecloud.io/nitrux/unison/gpgkey | apt-key add -;
curl -L https://packagecloud.io/nitrux/testing/gpgkey | apt-key add -;

apt -qq update

### Update GCC #1
### mauikit-imagetools is compiled against GCC 12.2 and CPP 12.

>> ubuntu-lunar.list printf "%s\n" \
    '################' \
    '# Ubuntu Lunar #' \
    '################' \
    '' \
    'deb [arch=amd64] http://archive.ubuntu.com/ubuntu lunar main restricted universe multiverse' \
    'deb [arch=amd64] http://archive.ubuntu.com/ubuntu lunar-security main restricted universe multiverse' \
    'deb [arch=amd64] http://archive.ubuntu.com/ubuntu lunar-updates main restricted universe multiverse' \
    ''

mv ubuntu-lunar.list /etc/apt/sources.list.d/

apt -qq update

apt -qq -yy install --no-install-recommends --only-upgrade \
	gcc

apt -qq update

### Install Package Build Dependencies #2

### Install Package Build Dependencies #2

apt -qq -yy install --no-install-recommends \
	kquickimageeditor \
	mauikit-filebrowsing-git \
	mauikit-git \
	mauikit-imagetools-git \
	qtbase-abi-5-15-8

### Download Source

git clone --depth 1 --branch $PIX_BRANCH https://invent.kde.org/maui/pix.git


### FIX Pix .desktop launcher
### See bug https://invent.kde.org/maui/pix/-/issues/26

sed -i 's+MimeType=image/gif;image/avif;image/jpeg;image/png;image/bmp;image/x-eps;image/x-ico;image/x-portable-bitmap;image/x-portable-graymap;image/x-portable-pixmap;image/x-xbitmap;image/x-xpixmap;image/tiff;image/x-psd;image/x-webp;image/webp;inode/directory;+MimeType=image/gif;image/avif;image/jpeg;image/png;image/bmp;image/x-eps;image/x-ico;image/x-portable-bitmap;image/x-portable-graymap;image/x-portable-pixmap;image/x-xbitmap;image/x-xpixmap;image/tiff;image/x-psd;image/x-webp;image/webp;+g' pix/src/org.kde.pix.desktop


### Compile Source

mkdir -p build && cd build

cmake \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DENABLE_BSYMBOLICFUNCTIONS=OFF \
	-DQUICK_COMPILER=ON \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_SYSCONFDIR=/etc \
	-DCMAKE_INSTALL_LOCALSTATEDIR=/var \
	-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON \
	-DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON \
	-DCMAKE_INSTALL_RUNSTATEDIR=/run "-GUnix Makefiles" \
	-DCMAKE_VERBOSE_MAKEFILE=ON \
	-DCMAKE_INSTALL_LIBDIR=/usr/lib/x86_64-linux-gnu ../pix/

make -j$(nproc)

make install

### Run checkinstall and Build Debian Package

>> description-pak printf "%s\n" \
	'MauiKit Image gallery manager.' \
	'' \
	'Pix is an image gallery manager made for Android and Plasma Mobile.' \
	'' \
	'Pix works under Android and GNU/Linux distros.' \
	'' \
	''

checkinstall -D -y \
	--install=no \
	--fstrans=yes \
	--pkgname=pix-git \
	--pkgversion=$PACKAGE_VERSION \
	--pkgarch=amd64 \
	--pkgrelease="1" \
	--pkglicense=LGPL-3 \
	--pkggroup=utils \
	--pkgsource=pix \
	--pakdir=. \
	--maintainer=uri_herrera@nxos.org \
	--provides=pix \
	--requires="kquickimageeditor,libc6,libexiv2-27,libgcc-s1,libkf5coreaddons5,libkf5i18n5,libqt5core5a,libqt5gui5,libqt5qml5,libqt5widgets5,libstdc++6,mauikit-git \(\>= 2.2.2+git\),mauikit-filebrowsing-git \(\>= 2.2.2+git\),mauikit-imagetools-git \(\>= 2.2.2+git\),qml-module-qt-labs-platform,qml-module-qtlocation,qml-module-qtpositioning" \
	--nodoc \
	--strip=no \
	--stripso=yes \
	--reset-uids=yes \
	--deldesc=yes

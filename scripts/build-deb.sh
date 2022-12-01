#! /bin/bash

set -x

### Update sources

wget -qO /etc/apt/sources.list.d/nitrux-main-compat-repo.list https://raw.githubusercontent.com/Nitrux/iso-tool/development/configs/files/sources/nitrux-repo.list

wget -qO /etc/apt/sources.list.d/nitrux-testing-repo.list https://raw.githubusercontent.com/Nitrux/iso-tool/development/configs/files/sources/nitrux-testing-repo.list

curl -L https://packagecloud.io/nitrux/repo/gpgkey | apt-key add -;
curl -L https://packagecloud.io/nitrux/compat/gpgkey | apt-key add -;
curl -L https://packagecloud.io/nitrux/testing/gpgkey | apt-key add -;

apt -qq update

### Install Package Build Dependencies #2

apt -qq -yy install --no-install-recommends \
	kquickimageeditor \
	mauikit-filebrowsing-git \
	mauikit-git \
	mauikit-imagetools-git

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
	-DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu ../pix/

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
	--requires="kquickimageeditor,libc6,libexiv2-27,libgcc-s1,libkf5coreaddons5,libkf5i18n5,libqt5core5a,libqt5gui5,libqt5qml5,libqt5widgets5,libstdc++6,mauikit-git \(\>= 2.2.1+git\),mauikit-filebrowsing-git \(\>= 2.2.1+git\),mauikit-imagetools-git \(\>= 2.2.1+git\),qml-module-qt-labs-platform,qml-module-qtlocation,qml-module-qtpositioning" \
	--nodoc \
	--strip=no \
	--stripso=yes \
	--reset-uids=yes \
	--deldesc=yes

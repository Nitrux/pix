#! /bin/bash

set -x

### Update sources

mkdir -p /etc/apt/keyrings

curl -fsSL https://packagecloud.io/nitrux/mauikit/gpgkey | gpg --dearmor -o /etc/apt/keyrings/nitrux_mauikit-archive-keyring.gpg

cat <<EOF > /etc/apt/sources.list.d/nitrux-mauikit.list
deb [signed-by=/etc/apt/keyrings/nitrux_mauikit-archive-keyring.gpg] https://packagecloud.io/nitrux/mauikit/debian/ trixie main
EOF

apt -q update

### Install Package Build Dependencies #2

apt -qq -yy install --no-install-recommends \
	mauikit-filebrowsing-git \
	mauikit-git \
	mauikit-imagetools-git \

### Download Source

git clone --depth 1 --branch $PIX_BRANCH https://invent.kde.org/maui/maui-pix

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
	-DCMAKE_INSTALL_LIBDIR=/usr/lib/x86_64-linux-gnu ../maui-pix/

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
	--requires="kio-extras,mauikit-filebrowsing-git \(\>= 4.0.1\),mauikit-git \(\>= 4.0.1\),mauikit-imagetools-git \(\>= 4.0.1\),qml6-module-qtcore,qml6-module-qtlocation,qml6-module-qtquick-effects" \
	--nodoc \
	--strip=no \
	--stripso=yes \
	--reset-uids=yes \
	--deldesc=yes

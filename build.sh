#!/bin/bash

# Set architecture from command-line argument or default to x86_64
ARCH="${1:-x86_64}"

# Validate architecture
if [[ ! "$ARCH" =~ ^(x86_64|aarch64)$ ]]; then
  echo "Error: Unsupported architecture '$ARCH'"
  echo "Supported architectures: x86_64, aarch64"
  exit 1
fi

TESTDISKURL="https://github.com/cgsecurity/testdisk"
APPIMAGETOOLURL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage"
LINUXDEPLOYURL="https://github.com/linuxdeploy/linuxdeploy/releases/latest/download/linuxdeploy-${ARCH}.AppImage"
LINUXDEPLOYQTURL="https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/latest/download/linuxdeploy-plugin-qt-${ARCH}.AppImage"

echo "Building for architecture: $ARCH"

wget "$APPIMAGETOOLURL"
chmod a+x appimagetool-${ARCH}.AppImage

git clone "$TESTDISKURL" --depth 1
cd testdisk

sed -i \
  -e 's|^TryExec=/usr/bin/qphotorec$|TryExec=qphotorec|' \
  -e 's|^Exec=/usr/bin/qphotorec %F$|Exec=qphotorec %F|' \
  linux/qphotorec.desktop

autoreconf -fi
./configure --prefix=/usr
make
make install DESTDIR="$PWD/QPhotoRec.AppDir"

chmod a+x QPhotoRec.AppDir/usr/bin/qphotorec

wget "$LINUXDEPLOYURL"
wget "$LINUXDEPLOYQTURL"

chmod a+x linuxdeploy-${ARCH}.AppImage
chmod a+x linuxdeploy-plugin-qt-${ARCH}.AppImage

export QMAKE=/usr/bin/qmake6
export NO_STRIP=1
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib:/usr/lib:/lib"

./linuxdeploy-${ARCH}.AppImage \
  --appdir QPhotoRec.AppDir \
  --desktop-file QPhotoRec.AppDir/usr/share/applications/qphotorec.desktop \
  --plugin qt

cd ..

./appimagetool-${ARCH}.AppImage testdisk/QPhotoRec.AppDir

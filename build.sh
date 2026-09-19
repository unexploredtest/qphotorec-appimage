#!/bin/bash


# Set architecture through the environment or default to x86_64
ARCH="${ARCH:-x86_64}"

# Set the TestDisk version tag through the environment or default to v7.2
VERSION_TAG="${VERSION_TAG:-v7.2}"

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

echo "Building TestDisk version: $VERSION_TAG"
echo "Building for architecture: $ARCH"

wget "$APPIMAGETOOLURL"
chmod a+x "appimagetool-${ARCH}.AppImage"

# Clone and check out the requested version tag
git clone \
  --branch "$VERSION_TAG" \
  --depth 1 \
  "$TESTDISKURL" \
  testdisk

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

# Use qmake6 only when VERSION_TAG is greater than v7.2 as they switch to qt6
VERSION="${VERSION_TAG#v}"

if [[ "$(printf '%s\n' '7.2' "$VERSION" | sort -V | tail -n1)" == "$VERSION" ]] \
  && [[ "$VERSION" != "7.2" ]]; then
  export QMAKE=/usr/bin/qmake6
fi

export NO_STRIP=1
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib:/usr/lib:/lib"

./linuxdeploy-${ARCH}.AppImage \
  --appdir QPhotoRec.AppDir \
  --desktop-file QPhotoRec.AppDir/usr/share/applications/qphotorec.desktop \
  --plugin qt

cd ..

./appimagetool-${ARCH}.AppImage testdisk/QPhotoRec.AppDir

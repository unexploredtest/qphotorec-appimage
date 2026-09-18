#!/bin/bash

TESTDISKURL="https://github.com/cgsecurity/testdisk"
APPIMAGETOOLURL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
LINUXDEPLOYURL="https://github.com/linuxdeploy/linuxdeploy/releases/latest/download/linuxdeploy-x86_64.AppImage"
LINUXDEPLOYQTURL="https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/latest/download/linuxdeploy-plugin-qt-x86_64.AppImage"

wget "$APPIMAGETOOLURL"
chmod a+x appimagetool-x86_64.AppImage

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

chmod a+x linuxdeploy-x86_64.AppImage
chmod a+x linuxdeploy-plugin-qt-x86_64.AppImage

export QMAKE=/usr/bin/qmake6
export NO_STRIP=1
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib:/usr/lib:/lib"

./linuxdeploy-x86_64.AppImage \
  --appdir QPhotoRec.AppDir \
  --desktop-file QPhotoRec.AppDir/usr/share/applications/qphotorec.desktop \
  --plugin qt

cd ..

./appimagetool-x86_64.AppImage testdisk/QPhotoRec.AppDir

#!/bin/bash

VER=2.0.20

wget --content-disposition https://github.com/libsdl-org/SDL/archive/release-${VER}.tar.gz -O SDL-repo.tar.gz
tar -xf SDL-repo.tar.gz
mv SDL-release-${VER} SDL2
rm -Rf SDL2/VisualC/
rm -Rf SDL2/VisualC-WinRT/
rm -Rf SDL2/visualtest/
rm -Rf SDL2/test/
rm -Rf SDL2/Xcode/
rm -Rf SDL2/Xcode-iOS/
mv SDL2/android-project/app/src/main/java/org/libsdl/app SDL2/android-java-files
rm -Rf SDL2/android-project/
rm -Rf SDL2/android-project-ant/

rm -Rf ../SDL2
mv SDL2 ../SDL2
rm SDL-repo.tar.gz

#! /bin/bash

if [ -d libs ]; then
    rm -rf libs
fi

if [ -d .haxelib ]; then
    rm -rf .haxelib
fi

mkdir libs
npm install .

cd .haxelib

libs=*
for lib in $libs; do
    mv $lib ../libs/$lib
done
    
cd ..
rm -rf .haxelib

cd libs
libs=*
for lib in $libs; do
    mv $lib/**/ $lib/$lib
    haxelib dev $lib $lib/$lib/
done
cd ..
cp $(haxelib libpath kiss)/build-scripts/dts2hx-externs/KillVersionReqs.hx ./
haxe --main KillVersionReqs --interp
rm KillVersionReqs.hx
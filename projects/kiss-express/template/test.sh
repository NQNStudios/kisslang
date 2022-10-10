#! /bin/bash

if [ ! -d node_modules ]; then
    $(haxelib libpath kiss)/build-scripts/dts2hx-externs/regenerate.sh
fi

haxe -D test build.hxml
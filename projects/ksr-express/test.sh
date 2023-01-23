#! /bin/bash

if [ ! -d node_modules ]; then
    $(haxelib libpath kiss)/build-scripts/dts2hx-externs/regenerate.sh
fi

haxe -D cards="$(pwd)/$1" -D engine="ksr_express.Engine" build.hxml
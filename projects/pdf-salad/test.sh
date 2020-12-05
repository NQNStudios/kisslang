#! /bin/bash

if [ ! -z "$TRAVIS_OS_NAME" ]; then
    npm install pdf-lib
fi
haxelib dev kiss ../../
haxe build.hxml
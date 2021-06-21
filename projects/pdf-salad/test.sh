#! /bin/bash

# Something is broken in the Node dependencies on Mac, so don't bother.
if [ "$CI_OS_NAME" = "macos-latest" ]; then
    exit 0
fi

if [ ! -z "$CI_OS_NAME" ]; then
    npm install pdf-lib
    haxelib install hxnodejs
fi
haxe build.hxml
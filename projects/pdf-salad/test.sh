#! /bin/bash

# Something is broken in the Node dependencies on Mac, so don't bother.
if [ "$TRAVIS_OS_NAME" = "osx" ]; then
    exit 0
fi

if [ ! -z "$TRAVIS_OS_NAME" ]; then
    npm install pdf-lib
    haxelib install hxnodejs
fi
haxe build.hxml
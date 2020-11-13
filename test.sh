#! /bin/bash

if [ ! -z "$TRAVIS_OS_NAME" ]
then
    haxelib install utest
    haxelib install hxnodejs
fi

HISS_TARGET=${HISS_TARGET:-$1}
HISS_TARGET=${HISS_TARGET:-interp}
haxe src/build-scripts/test/$HISS_TARGET.hxml
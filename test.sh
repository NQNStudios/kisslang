#! /bin/bash

HISS_TARGET=${HISS_TARGET:-$1}
HISS_TARGET=${HISS_TARGET:-interp}

if [ ! -z "$TRAVIS_OS_NAME" ]
then
    (cd src/build-scripts && haxelib install all)
    (cd src/build-scripts/$HISS_TARGET && haxelib install all)
fi

haxe src/build-scripts/$HISS_TARGET/test.hxml
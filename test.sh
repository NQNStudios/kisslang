#! /bin/bash

KISS_TARGET=${KISS_TARGET:-$1}
KISS_TARGET=${KISS_TARGET:-interp}

# For CI tests, force install the dependencies
if [ ! -z "$TRAVIS_OS_NAME" ]
then
    (cd src/build-scripts && haxelib install all --always)
    (cd src/build-scripts/$KISS_TARGET && haxelib install all --always)
fi

haxe src/build-scripts/common-args.hxml src/build-scripts/common-test-args.hxml src/build-scripts/$KISS_TARGET/test.hxml
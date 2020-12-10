#! /bin/bash

KISS_TARGET=${KISS_TARGET:-$1}
KISS_TARGET=${KISS_TARGET:-interp}

if [ "$KISS_TARGET" = "projects" ]
then
    KISS_HEADLESS="$TRAVIS_OS_NAME" ./test-projects.sh
else
    # For CI tests, force install the dependencies
    if [ ! -z "$TRAVIS_OS_NAME" ]
    then
        (cd kiss/build-scripts && haxelib install all --always)
        (cd kiss/build-scripts/$KISS_TARGET && haxelib install all --always)
    fi

    haxe kiss/build-scripts/common-args.hxml kiss/build-scripts/common-test-args.hxml kiss/build-scripts/$KISS_TARGET/test.hxml
fi

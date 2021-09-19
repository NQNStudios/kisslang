#! /bin/bash

KISS_PROJECT=${KISS_PROJECT:-$1}
KISS_PROJECT=${KISS_PROJECT:-aoc}

./test-env.sh

# If project folder contains "flixel-", test that its code compiles for HTML5 and C++
if [[ $KISS_PROJECT == *flixel-* ]]
then
    # If running through Travis, install HaxeFlixel with c++ tooling
    if [ ! -z "CI_OS_NAME" ]
    then
        haxelib install lime
        haxelib install openfl
        haxelib install flixel
        haxelib install flixel-addons
        haxelib install flixel-ui
        haxelib install hxcpp
    fi

    # if "desktop-" is in the project name, only test for C++
    if [[ $KISS_PROJECT == *desktop-* ]]
    then
        (cd projects/$KISS_PROJECT && echo "Building $KISS_PROJECT for cpp" && haxelib run lime build cpp)
    # if "web-" is in the project name, only test for HTML5
    elif [[ $KISS_PROJECT == *web-* ]]
        (cd projects/$KISS_PROJECT && echo "Building $KISS_PROJECT for html5" && haxelib run lime build html5)
    # Otherwise require both to succeed
    else
        (cd projects/$KISS_PROJECT && echo "Building $KISS_PROJECT for html5" && haxelib run lime build html5) && \
        (cd projects/$KISS_PROJECT && echo "Building $KISS_PROJECT for cpp" && haxelib run lime build cpp)
    fi
# Test other projects with their test.sh file
else
    (cd projects/$KISS_PROJECT && haxelib install all --always)
    (cd projects/$KISS_PROJECT && ./test.sh "${@:2}")
fi
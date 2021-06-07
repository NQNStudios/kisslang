#! /bin/bash

KISS_PROJECT=${KISS_PROJECT:-$1}
KISS_PROJECT=${KISS_PROJECT:-aoc}

haxelib dev kiss kiss

# If project folder contains "nat-", set development directory for nat-archive-tool
if [[ $KISS_PROJECT == *nat-* ]]
then
    haxelib dev nat-archive-tool projects/nat-archive-tool
fi

# If project folder contains "ascii-", set development directory for asciilib2
if [[ $KISS_PROJECT == *ascii-* ]]
then
    haxelib dev asciilib projects/asciilib2
fi

# If project folder contains "flixel-", test that its code compiles for HTML5 and C++
if [[ $KISS_PROJECT == *flixel-* ]]
then
    # If running through Travis, install HaxeFlixel with c++ tooling and 
    if [ ! -z "$TRAVIS_OS_NAME" ]
    then
        haxelib install lime
        haxelib install openfl
        haxelib install flixel
        haxelib install flixel-addons
        haxelib install hxcpp
    fi

    echo "Building $KISS_PROJECT for html5"
    (cd projects/$KISS_PROJECT && haxelib run lime build html5)
    echo "Building $KISS_PROJECT for cpp"
    (cd projects/$KISS_PROJECT && haxelib run lime build cpp)
# Test other projects with their test.sh file
else
    (cd projects/$KISS_PROJECT && haxelib install all --always)
    (cd projects/$KISS_PROJECT && ./test.sh)
fi
#! /bin/bash

haxelib dev kiss kiss

# Every library with a haxelib.json should be made available to every other project/unit test
libraries=$(ls libraries)
for lib in $libraries
do
    if [ -e libraries/${lib}/haxelib.json ]
    then
        haxelib dev $lib libraries/$lib
    fi
done
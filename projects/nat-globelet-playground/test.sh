#! /bin/bash

if [ ! -d node_modules ]; then
    npm install .
fi
# npm install creates a .haxelib folder which needs to be pointed to the dependencies
if [ ! -d .haxelib/kiss ]; then
    cp .haxelib/express/.current .haxelib/express/.current.tmp
    (cp ../../kiss/build-scripts/common-args.hxml ./ && haxelib install all --always && rm common-args.hxml)
    # install all introduces an out-of-date express haxelib
    mv .haxelib/express/.current.tmp .haxelib/express/.current

    haxelib dev kiss ../../kiss
    projects=$(ls ..)
    for project in $projects
    do
        if [ -e ../${project}/haxelib.json ]
        then
            haxelib dev $project ../$project
            # the word project has lost all meaning at this point
        fi
    done
fi
haxe -D test build.hxml
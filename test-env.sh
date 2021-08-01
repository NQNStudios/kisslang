#! /bin/bash

haxelib dev kiss kiss

# Every project with a haxelib.json should be made available to every other project/unit test
projects=$(ls projects)
for project in $projects
do
    if [ -e projects/${project}/haxelib.json ]
    then
        haxelib dev $project projects/$project
        # the word project has lost all meaning at this point
    fi
done
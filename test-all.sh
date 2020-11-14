#! /bin/bash

# For local testing. Dependencies won't be installed

TEST_FILES=src/build-scripts/**/test.hxml

for TEST_FILE in $TEST_FILES
do
    echo $TEST_FILE
    haxe src/build-scripts/common-args.hxml src/build-scripts/common-test-args.hxml $TEST_FILE
    if [ ! $? -eq 0 ]
    then
        exit $?
    fi
done
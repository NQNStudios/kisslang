#! /bin/bash

# For local testing. Runs manual project tests, which cannot run headless.
# Dependencies won't be installed first

# Test the Kiss compiler on every target language:
TEST_FILES=kiss/build-scripts/**/test.hxml

for TEST_FILE in $TEST_FILES
do
    echo $TEST_FILE
    haxe kiss/build-scripts/common-args.hxml kiss/build-scripts/common-test-args.hxml $TEST_FILE
    if [ ! $? -eq 0 ]
    then
        exit 1
    fi
done

./test-projects.sh
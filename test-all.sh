#! /bin/bash
TEST_FILES=src/build-scripts/**/test.hxml
for TEST_FILE in $TEST_FILES
do
	haxe $TEST_FILE
    if [ ! $? -eq 0 ]
    then
        exit $?
    fi
done

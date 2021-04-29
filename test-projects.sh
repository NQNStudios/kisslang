#! /bin/bash
# Test the Kiss projects. If run manually, this runs extra manual tests that may involve GUI stuff.
PROJECT_DIRS=projects/**/

if [ ! -z "${TRAVIS_OS_NAME}" ]; then
    # Install basic dependencies for Kiss testing
    (cd kiss/build-scripts && haxelib install all --always)
    
    # Install HaxeFlixel with c++ tooling because many Kiss projects use it
    haxelib install lime
    haxelib install openfl
    haxelib install flixel
    haxelib install hxcpp
fi

for PROJECT_DIR in $PROJECT_DIRS
do
    if [ ! -z "${TRAVIS_OS_NAME}" ]; then
        haxelib dev kiss kiss
        (cd $PROJECT_DIR && haxelib install all --always)
    fi

    AUTO_TEST_FILE=${PROJECT_DIR}test.sh
    if [ -e $AUTO_TEST_FILE ]
    then
        echo $AUTO_TEST_FILE
        (cd $PROJECT_DIR && ./test.sh)
        if [ ! $? -eq 0 ]
        then
            echo "failed"
            exit 1
        fi
    fi
    
    MANUAL_TEST_FILE=${PROJECT_DIR}manual-test.sh
    if [ -z "$KISS_HEADLESS" ] && [ -e $MANUAL_TEST_FILE ]
    then
        echo $MANUAL_TEST_FILE
        (cd $PROJECT_DIR && ./manual-test.sh)
        if [ ! $? -eq 0 ]
        then
            echo "failed"
            exit 1
        fi
    fi
done
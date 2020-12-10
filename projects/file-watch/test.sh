#! /bin/bash

echo "" > test-output.txt
expected=$'hey\nhey\nhey'
if [[ $(uname) == *"MINGW"* ]] || [ $TRAVIS_OS_NAME = "windows" ]; then
    expected=$'"hey" \r\n"hey" \r\n"hey"' 
fi

whichpy=python
# "python" is supposed to mean Python3 everywhere now, but not in practice
if [ ! -z "$(which python3)" ]; then
    whichpy=python3
fi

haxe build.hxml && \
# Give extra time to reach 3 "hey"s
timeout 0.5 $whichpy bin/main.py test-file.txt 0.1 "echo {} >> test-output.txt" 0  || \
if [[ "$(cat test-output.txt)" != *"$expected"* ]]
then
    echo "$(cat test-output.txt) should be $expected"
    exit 1
fi
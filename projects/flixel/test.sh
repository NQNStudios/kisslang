#! /bin/bash

# Make sure the examples with backends compile, at least:
EXAMPLE_DIRS=./**/

for EXAMPLE_DIR in $EXAMPLE_DIRS
do
    echo "Building $EXAMPLE_DIR for html5"
    (cd $EXAMPLE_DIR && haxelib run lime build html5)
    echo "Building $EXAMPLE_DIR for cpp"
    (cd $EXAMPLE_DIR && haxelib run lime build cpp)
done
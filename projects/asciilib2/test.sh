#! /bin/bash

haxelib dev asciilib .

# Run the headless unit tests:
echo "Running headless ASCIILib tests"
(cd test && haxe build.hxml)
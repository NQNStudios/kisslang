#! /bin/bash

# Run the build without -D test first, to make sure it works that way too:
haxe build.hxml && haxe -D test build.hxml -cmd "node bin/extension.js"
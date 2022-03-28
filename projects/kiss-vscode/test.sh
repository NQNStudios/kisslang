#! /bin/bash

# Run the build without -D test first, to make sure it works that way too:
echo "!test" && haxe build.hxml && echo "test" && haxe -D test build.hxml -cmd "node bin/extension.js"
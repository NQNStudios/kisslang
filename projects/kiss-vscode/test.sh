#! /bin/bash

haxe build.hxml && haxe -D test build.hxml -cmd "node bin/extension.js"
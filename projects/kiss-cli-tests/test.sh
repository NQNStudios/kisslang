#! /bin/bash

# Test kiss new-project command
if [ -d TestNewProject ]; then
    rm -rf TestNewProject
fi &&
cat new-project-input.txt | haxelib run kiss new-project && (cd TestNewProject && sh test.sh) &&

# Test kiss new-express-project command
haxelib install hxnodejs &&
if [ -d testnewexpressproject ]; then
    rm -rf testnewexpressproject
fi &&
cat new-express-project-input.txt | haxelib run kiss new-express-project && (cd testnewexpressproject && sh test.sh) &&

# Test kiss new-flixel-project command
if [ ! -z "$CI_OS_NAME" ]
then
    haxelib install lime
    haxelib install openfl
    haxelib install flixel
fi &&
if [ -d TestNewFlixelProject ]; then
    rm -rf TestNewFlixelProject
fi &&
cat new-flixel-project-input.txt | haxelib run kiss new-flixel-project && (cd TestNewFlixelProject && haxelib run lime build neko)

# &&
# TODO test other kiss project templates
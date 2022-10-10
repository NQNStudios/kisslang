#! /bin/bash

# Test kiss new-project command
if [ -d TestNewProject ]; then
    rm -rf TestNewProject
fi
cat new-project-input.txt | haxelib run kiss new-project && (cd TestNewProject && sh test.sh)

# Test kiss new-express-project command
if [ -d testnewexpressproject ]; then
    rm -rf testnewexpressproject
fi
cat new-express-project-input.txt | haxelib run kiss new-express-project && (cd testnewexpressproject && sh test.sh)

# TODO test other kiss project templates

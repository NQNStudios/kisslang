#! /bin/bash

# Test kiss new-project command
cat new-project-input.txt | haxelib run kiss new-project && (cd TestNewProject && sh test.sh)

# TODO test other kiss project templates

#! /bin/bash

haxelib dev kiss ../../
haxe build.hxml
python bin/main.py test
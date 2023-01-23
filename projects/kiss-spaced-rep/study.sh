#! /bin/bash

ENGINE=${2:-kiss_spaced_rep.ConsoleEngine}

haxe -D cards="$(pwd)/$1" -D engine="$ENGINE" build.hxml
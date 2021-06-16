#! /bin/bash

DAYS=${1:-all}
YEARS=${2:-all}
haxe -D test -lib kiss -cp src --run Main $DAYS $YEARS
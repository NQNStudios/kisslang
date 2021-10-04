#! /bin/bash

for dir in export/**/bin; do
    if [ -d $dir/bin ]; then
        rm -rf $dir/bin
    fi
    cp -r bin $dir/bin
done
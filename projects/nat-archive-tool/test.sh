#! /bin/bash

# Run these tests on every target that could be used for a NAT front-end
# (also to test (#extern) on multiple targets)
haxe test.hxml py.hxml &&
haxe test.hxml js.hxml &&
haxe test.hxml cpp.hxml &&
haxe test.hxml --interp

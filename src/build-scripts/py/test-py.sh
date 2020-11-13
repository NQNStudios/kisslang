#! /bin/bash

# Travis testing on Xenial
if [ "$(uname)" = "Linux" ]; then
    python3 bin/py/test.py
else
    python bin/py/test.py
fi
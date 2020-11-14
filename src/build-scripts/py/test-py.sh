#! /bin/bash

# "python" is supposed to mean Python3 everywhere now, but not in practice
if [ ! -z "$(which python3)" ]; then
    python3 bin/py/test.py
else
    python bin/py/test.py
fi
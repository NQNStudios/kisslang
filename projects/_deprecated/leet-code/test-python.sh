# "python" is supposed to mean Python3 everywhere now, but not in practice
if [ ! -z "$(which python3)" ]; then
    python3 main.py
else
    python main.py
fi
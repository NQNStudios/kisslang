import sys

def arg(num, usage, default=None):
    val = ''
    if len(sys.argv) > num:
        val = sys.argv[num]
    else:
        if default != None:
            return default
        raise ValueError(usage)
    return val
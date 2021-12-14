import sys

def arg(num, usage):
    val = ''
    if len(sys.argv) > num:
        val = sys.argv[num]
    else:
        raise ValueError(usage)
    return val
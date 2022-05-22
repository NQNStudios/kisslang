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

def args(starting_num, usage, default=None):
    l = []
    if len(sys.argv) > starting_num:
        l = sys.argv[starting_num:]
    else:
        if default != None:
            return default
        raise ValueError(usage)
    return l
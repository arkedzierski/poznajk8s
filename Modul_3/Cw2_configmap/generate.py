#!/usr/bin/python

import sys

N = int(sys.argv[1])

print("\n".join([ "key"+str(i)+" = value"+str(i) for i in range(N)]))
#! /usr/bin/python
from TOSSIM import *
import sys

linkgain = sys.argv[1];
print linkgain;

t = Tossim([])
r = t.radio()

# Read in topology of 3-node network from linkgain.out
# add link and gain to radio module.
f = open("linkgain.out", "r")
for line in f:
    s = line.split()
    if (len(s) > 0):
        if (s[0] == "gain"):
            r.add(int(s[1]), int(s[2]), float(s[3]))

t.addChannel("SendMessageC", sys.stdout)
t.addChannel("Boot", sys.stdout)

noise = open("meyer-heavy.txt", "r")
for i in range(0,100):
    str1 = noise.next().strip()
    if str1:
        val = int(str1)
        for i in range(0, 49):
            t.getNode(i).addNoiseTraceReading(val)

for i in range(0,49):
    print "Creating noise model for ",i;
    t.getNode(i).createNoiseModel()

for i in range(0,49):
    t.getNode(i).bootAtTime(i*10000);

for i in range(0,1000):
    t.runNextEvent()


#! /usr/bin/python
from TOSSIM import *
import sys

linkgain = sys.argv[1];
non = 49; # number of nodes.

t = Tossim([]);
r = t.radio();

# Read in topology of 3-node network from linkgain.out
# add link and gain to radio module.
f = open(linkgain, "r")
for line in f:
    s = line.split()
    if (len(s) > 0):
        if (s[0] == "gain"):
            r.add(int(s[1]), int(s[2]), float(s[3]))

t.addChannel("TrickleC", sys.stdout)
t.addChannel("Boot", sys.stdout)

noise = open("meyer-heavy.txt", "r")
lines = noise.readlines()
for line in lines:
    str1 = line.strip()
    if str1:
        val = int(str1)
        for i in range(non):
            t.getNode(i).addNoiseTraceReading(val)

for i in range(non):
    print "Creating noise model for ",i;
    t.getNode(i).createNoiseModel()

for i in range(non):
    t.getNode(i).bootAtTime(i*10000 + 566871);

t.runNextEvent();
time = t.time();
while time + 300000000000 > t.time():
    t.runNextEvent()


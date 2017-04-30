#!/bin/bash

basepath=/afs/unity.ncsu.edu/users/a/amuckad/SDN/SDNCase

echo "Collecting stats from all the routers" >> $basepath/sdncase.log
sh $basepath/collectstats.sh

echo "Calculating link costs" >> $basepath/sdncase.log
sh $basepath/getlinkcosts.sh

echo "Running All-pair shortest path algorithm" >> $basepath/sdncase.log
python $basepath/apsp.py

echo "Updating flow entries in the routers" >> $basepath/sdncase.log
sh $basepath/updatelinkcosts.sh



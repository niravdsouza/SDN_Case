#!/bin/bash

export PATH="/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/sbin:/usr/sbin:/usr/local/sbin:/sbin:/usr/sbin:/usr/local/sbin"
basepath=/afs/unity.ncsu.edu/users/a/amuckad/SDN/SDNCase

N=`cat $basepath/reference/configs.conf | grep N= | cut -d= -f2`
rm -f $basepath/reference/previous/previous_bytes.*
rm -f $basepath/received/current_bytes.*
rm -f $basepath/history/historicaldata.*

for rou in $(cat $basepath/reference/configs.conf | grep ^routers= | cut -d= -f2 | sed 's/,/ /g')
do
        for int in $(cat $basepath/reference/configs.conf | grep ^$rou"=" | cut -d= -f2 | sed 's/,/ /g')
        do
                echo "RX:0" > $basepath/reference/previous/previous_bytes.$rou.$int
                echo "TX:0" >> $basepath/reference/previous/previous_bytes.$rou.$int

                echo "RX:0" > $basepath/received/current_bytes.$rou.$int
                echo "TX:0" >> $basepath/received/current_bytes.$rou.$int

                > $basepath/history/historicaldata.$rou.$int
                for i in $(seq 1 $N)
                do
                        echo 0 >> $basepath/history/historicaldata.$rou.$int
                done
        done
done



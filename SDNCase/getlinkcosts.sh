#!/bin/bash

export PATH="/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/sbin:/usr/sbin:/usr/local/sbin:/sbin:/usr/sbin:/usr/local/sbin"

basepath=/afs/unity.ncsu.edu/users/a/amuckad/SDN/SDNCase
p=`cat $basepath/reference/configs.conf | grep p= | cut -d= -f2`
L=`cat $basepath/reference/configs.conf | grep L= | cut -d= -f2`
n=`cat $basepath/reference/configs.conf | grep n= | cut -d= -f2`
N=`cat $basepath/reference/configs.conf | grep N= | cut -d= -f2`

date >> $basepath/sdncase.log

#####################################################
# Inserting the new information into required files #
#####################################################

echo "Calculating utilization and adding to historical db" >> $basepath/sdncase.log

for rou in $(cat $basepath/reference/configs.conf | grep ^routers= | cut -d= -f2 | sed 's/,/ /g')
do
	for int in $(cat $basepath/reference/configs.conf | grep ^$rou"=" | cut -d= -f2 | sed 's/,/ /g')
	do
		echo "For Router $rou Interface $int" >> $basepath/sdncase.log
		
		current_tx=`cat $basepath/received/current_bytes.$rou.$int | grep TX | cut -d: -f2`
		current_rx=`cat $basepath/received/current_bytes.$rou.$int | grep RX | cut -d: -f2`
		echo "Current bytes: $current_tx" >> $basepath/sdncase.log

		previous_tx=`cat $basepath/reference/previous/previous_bytes.$rou.$int | grep TX | cut -d: -f2`
		#previous_rx=`cat $basepath/reference/previous/previous_bytes.$rou.$int | grep RX | cut -d: -f2`
		echo "Previous bytes: $previous_tx" >> $basepath/sdncase.log

		diff_tx=`expr $current_tx - $previous_tx`
		echo "Difference: $diff_tx" >> $basepath/sdncase.log

		bandwidth=`cat $basepath/reference/configs.conf | grep $rou.$int"_bandwidth" | cut -d= -f2`
		echo "Bandwidth: $bandwidth" >> $basepath/sdncase.log

		utilization=`expr $diff_tx \* 100 / $p / $bandwidth`
		if [ $utilization -gt 100 ]
		then
			utilization=100
		fi
		echo "Utilization: $utilization" >> $basepath/sdncase.log

		echo $utilization >> $basepath/history/historicaldata.$rou.$int
		echo "RX:$current_rx" > $basepath/reference/previous/previous_bytes.$rou.$int
		echo "TX:$current_tx" >> $basepath/reference/previous/previous_bytes.$rou.$int
	done
done

###############################################
# Calculating link costs from historical data #
###############################################

echo "Calculating link cost from historical db" >> $basepath/sdncase.log

> $basepath/reference/tempfiles/linkcosts
for link in $(cat $basepath/reference/configs.conf | grep ^links= | cut -d= -f2 | sed 's/,/ /g')
do
	echo "For Link $link" >> $basepath/sdncase.log
	sum=0
	num=0
	for rouint in $(cat $basepath/reference/configs.conf | grep ^$link"=" | cut -d= -f2 | sed 's/:/ /g')
	do
		count=`cat $basepath/history/historicaldata.$rouint | wc -l`
		i=1
		while [ $i -lt $count ]
		do
			val=`sed -n $i'p' $basepath/history/historicaldata.$rouint`
			sum=`expr $sum + $val`
			i=`expr $i + $L`
			num=`expr $num + 1`
		done

		if [ $count -gt $N ]
		then
			sed -i '1d' $basepath/history/historicaldata.$rouint
		fi
	done

	avg_utilization=`expr $sum / $num`
	echo "Average utilization $avg_utilization" >> $basepath/sdncase.log

	sed '1d' $basepath/reference/linkcosts | while read line
	do
		lower=`echo $line | cut -d, -f1`
		upper=`echo $line | cut -d, -f2`

		if [ $avg_utilization -ge $lower ]
		then
			if [ $avg_utilization -le $upper ]
			then
				tablecost=`echo $line | cut -d, -f3`
				multiplication_factor=`cat $basepath/reference/configs.conf | grep $link"_multiplication_factor" | cut -d= -f2`
				linkcost=`expr $tablecost \* $multiplication_factor`
				echo "$link:$linkcost" >> $basepath/reference/tempfiles/linkcosts
				echo "Link cost $linkcost" >> $basepath/sdncase.log
				break
			fi
		fi
	done
done

#####################################################################
# Putting link costs in graph format required to run Floyd-Warshall #
#####################################################################

echo "Creating graph for APSP algorithm" >> $basepath/sdncase.log

echo "{" > $basepath/reference/tempfiles/graph
for rou in $(cat $basepath/reference/configs.conf | grep ^routers= | cut -d= -f2 | sed 's/,/ /g')
do
	router=`echo $rou | sed 's/[^0-9]*//g'`
	echo "$router : {" >> $basepath/reference/tempfiles/graph
done
echo "}" >> $basepath/reference/tempfiles/graph

for link in $(cat $basepath/reference/configs.conf | grep ^links= | cut -d= -f2 | sed 's/,/ /g')
do
	routerA=`cat $basepath/reference/configs.conf | grep ^$link"=" | cut -d= -f2 | cut -d: -f1 | cut -d. -f1 | sed 's/[^0-9]*//g'`
	routerB=`cat $basepath/reference/configs.conf | grep ^$link"=" | cut -d= -f2 | cut -d: -f2 | cut -d. -f1 | sed 's/[^0-9]*//g'`
	linkcost=`cat $basepath/reference/tempfiles/linkcosts | grep $link":" | cut -d: -f2`
	linkcostA=$routerB:$linkcost
	linkcostB=$routerA:$linkcost
	sed -i "/$routerA : {/s/$/$linkcostA,/" $basepath/reference/tempfiles/graph
	sed -i "/$routerB : {/s/$/$linkcostB,/" $basepath/reference/tempfiles/graph
done

sed -i 's/\(.*\),/\1},/' $basepath/reference/tempfiles/graph

cat $basepath/reference/tempfiles/graph >> $basepath/sdncase.log



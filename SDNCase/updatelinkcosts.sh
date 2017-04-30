#!/bin/bash

export PATH="/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/sbin:/usr/sbin:/usr/local/sbin:/sbin:/usr/sbin:/usr/local/sbin"

basepath=/afs/unity.ncsu.edu/users/a/amuckad/SDN/SDNCase/
netmask=`cat $basepath/reference/configs.conf | grep "netmask=" | cut -d= -f2`
sed '1d' $basepath/reference/tempfiles/updatelist | sed '/^$/d' | while read toupdate
do
	from=`echo $toupdate | cut -d, -f1`
	routerDPID=`cat $basepath/reference/configs.conf | grep $from"_dpid=" | cut -d= -f2`
	to=`echo $toupdate | cut -d, -f2`
	hostIP=`cat $basepath/reference/configs.conf | grep $to"=" | cut -d= -f2`
	port=`echo $toupdate | cut -d, -f3`
	outputport=`cat $basepath/reference/configs.conf | grep $from"_port:router"$port | cut -d= -f2`

	updatecommand=`cat $basepath/reference/updatecommand | sed "/ipv4_dst/s/$/\"$hostIP\/$netmask\",/" | sed "/port/s/$/$outputport/" | sed "/dpid/s/$/$routerDPID/"`
	echo $updatecommand
done



#!/bin/bash

PING_TARGET="8.8.8.8"
PING_MAX_Latency=300

Gateway_Primary="192.168.0.1"
Gateway_Interface_Primary="eth0"

Gateway_Backup="192.168.178.1"
Gateway_Interface_Backup="wlan0"

Current_Gateway=$Gateway_Interface_Primary
ifmetric $Gateway_Interface_Primary 200
ifmetric $Gateway_Interface_Backup 300

checkLatency () {
	Test_Latency=$(ping -c 3 -I $1 $PING_TARGET | awk -F '/' 'END {print $4}' | awk -F '=' 'END {print $2}') # minimal ms

	echo $Test_Latency " at " $1
	echo "current gateway " $Current_Gateway
	
	if [ "${Test_Latency%\.*}" -gt "$PING_MAX_Latency" ]
	then
		if [ "$Current_Gateway" = "$Gateway_Interface_Primary" ]
		then
			#echo "too long, switch to backup"
			Current_Gateway=$Gateway_Interface_Backup
			ifmetric $Gateway_Interface_Backup 100
		fi
	else
		if [ "$Current_Gateway" = "$Gateway_Interface_Backup" ]
		then
			#echo "ok, switch back to primary"
			ifmetric $Gateway_Interface_Backup 300
		fi
		#echo "ok"
	fi
}

while true
do
	#echo "..........."
	checkLatency $Gateway_Interface_Primary
	sleep 15
done


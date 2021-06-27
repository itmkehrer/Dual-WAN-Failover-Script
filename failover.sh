#!/bin/bash

exec >/var/log/failover_script.log 2>&1

PING_TARGET="8.8.8.8"
PING_MAX_Latency=300

Gateway_Primary="192.168.0.1"
Gateway_Interface_Primary="eth0"

Gateway_Backup="192.168.178.1"
Gateway_Interface_Backup="wlan0"

Current_Gateway=$Gateway_Interface_Primary
ifmetric $Gateway_Interface_Primary 200
ifmetric $Gateway_Interface_Backup 300

echo "Start failover script at " $(date +"%Y-%m-%d %X")

checkLatency () {
	Test_Latency=$(ping -c 3 -I $1 $PING_TARGET | awk -F '/' 'END {print $4}' | awk -F '=' 'END {print $2}') # minimal ms
	
	#echo $Test_Latency
	
	if [ -z "${Test_Latency%\.*}" ]
	then
		echo "ping failed"
		Test_Latency=10000
	fi
	
	if [ "$PING_MAX_Latency" -lt "${Test_Latency%\.*}" ]
	then
		echo $Test_Latency " at " $1 " time:" $(date +"%Y-%m-%d %X")
		if [ "$Current_Gateway" = "$Gateway_Interface_Primary" ]
		then
			echo "too long, switch to backup" " time:" $(date +"%Y-%m-%d %X")
			Current_Gateway=$Gateway_Interface_Backup
			ifmetric $Gateway_Interface_Backup 100
		fi
	else
		if [ "$Current_Gateway" = "$Gateway_Interface_Backup" ]
		then
			echo "ok, switch back to primary" " time:" $(date +"%Y-%m-%d %X")
			ifmetric $Gateway_Interface_Backup 300
			Current_Gateway=$Gateway_Interface_Primary
		fi
		#echo "ok"
	fi
}

while true
do
	checkLatency $Gateway_Interface_Primary
	sleep 15
done


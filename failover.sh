#!/bin/sh

exec >/var/log/failover_script_"$(date '+%Y-%m-%d')".log 2>&1

PING_TARGET="8.8.8.8"
PING_TARGET2="1.1.1.1"
PING_MAX_Latency=300

#Gateway_Primary="192.168.0.1"
Gateway_Interface_Primary="eth0"

#Gateway_Backup="192.168.178.1"
Gateway_Interface_Backup="wlan0"

sleep 10

Current_Gateway=$Gateway_Interface_Primary
/usr/sbin/ifmetric $Gateway_Interface_Primary 200
/usr/sbin/ifmetric $Gateway_Interface_Backup 300

echo "Start failover script at $(date +"%Y-%m-%d %X")"

checkLatency () {
	Test_Latency=$(ping -c 3 -I "$1" $PING_TARGET) 
	Test_Latency_ms=$(echo "$Test_Latency" | awk -F '/' 'END {print $4}' | awk -F '=' 'END {print $2}') # minimal ms

	#echo $Test_Latency
	#echo $Test_Latency_ms

	if [ -z "${Test_Latency_ms%\.*}" ]
	then
		echo "ping failed at $(date +"%Y-%m-%d %X")"
		echo "$Test_Latency"
		
		Test_Latency2=$(ping -c 3 -I "$1" $PING_TARGET2) 
		Test_Latency_ms2=$(echo "$Test_Latency2" | awk -F '/' 'END {print $4}' | awk -F '=' 'END {print $2}') # minimal ms

		if [ -z "${Test_Latency_ms2%\.*}" ]
		then
			echo "ping2 failed at $(date +"%Y-%m-%d %X")"
			echo "$Test_Latency2"
			Test_Latency_ms=10000
		else
			echo "ping2 is ok - $Test_Latency_ms2 ms at $(date +"%Y-%m-%d %X")"
			Test_Latency_ms=$Test_Latency_ms2
		fi
	fi
	
	if [ "$PING_MAX_Latency" -lt "${Test_Latency_ms%\.*}" ]
	then
		echo "$Test_Latency_ms ms on $1 at $(date +"%Y-%m-%d %X")"
		if [ "$Current_Gateway" = "$Gateway_Interface_Primary" ]
		then
			Test_Latency2=$(ping -c 3 -I "$1" $PING_TARGET2) 
			Test_Latency_ms2=$(echo "$Test_Latency2" | awk -F '/' 'END {print $4}' | awk -F '=' 'END {print $2}') # minimal ms
			if [ -z "${Test_Latency_ms2%\.*}" ]
			then
				echo "ping2 failed at $(date +"%Y-%m-%d %X")"
				echo "$Test_Latency2"
				
				echo "switch to backup at $(date +"%Y-%m-%d %X")"
				Current_Gateway=$Gateway_Interface_Backup
				/usr/sbin/ifmetric $Gateway_Interface_Backup 100
			else
				if [ "$PING_MAX_Latency" -lt "${Test_Latency_ms2%\.*}" ]
				then
					echo "ping2 too long - $Test_Latency_ms2 -switch to backup at $(date +"%Y-%m-%d %X")"
					Current_Gateway=$Gateway_Interface_Backup
					/usr/sbin/ifmetric $Gateway_Interface_Backup 100
				else
					echo "ping2 is ok - $Test_Latency_ms2 - at $(date +"%Y-%m-%d %X")"
				fi
			fi
		fi
	else
		if [ "$Current_Gateway" = "$Gateway_Interface_Backup" ]
		then
			echo "ok, switch back to primary at $(date +"%Y-%m-%d %X")"
			/usr/sbin/ifmetric $Gateway_Interface_Backup 300
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


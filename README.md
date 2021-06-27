# Dual WAN Failover Script Linux

This script pings every 15 secounds Google DNS over the main WAN. 
If the minimal latency is over 500ms it changes the route metric, so the traffic goes over WAN2.
When the main WAN latency recovers back to under 500ms, it change the route metric back.

Most of the other Scripts are just removing the second route, but i want to reach the second network at any time.

To run that script you need to install the paket "ifmetric".

This is for example my network
![image](https://user-images.githubusercontent.com/10454554/123535376-c7bfe000-d723-11eb-8e9a-e65efa00d02d.png)

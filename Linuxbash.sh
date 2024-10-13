#!/bin/bash

####Script Created By Sruthi TS - 07/June/2021
###Azure Linux VM healcheck



#Declaring urlarray
declare -a urllist
urllist=(sensors.smooth-owl.my.cbcloud.de,443,CB_EMEIA
sensors.marvellous-elephant.my.carbonblack.io,443,CB_AMERICAS
sensors.powerful-flamingo.my.cbcloud.sg,443,CB_APAC
qagpublic.qg1.apps.qualys.com,443,QUALYS
sepm.ey.com,443,SEP
liveupdate.symantec.com,80,LIVEUPDATE
scwp.securitycloud.symantec.com,443,CWP)

#Function for service status
function servicestatus(){
systemctl is-active --quiet $2
if [ `echo $?` == 0 ]; then
echo "    \"$1\": \"Running\","
else
systemctl cat $2  > /dev/null 2>&1
if [ `echo $?` == 0 ]; then
echo "    \"$1\": \"Stopped\","
else
echo "    \"$1\": \"Service Not Found\","
fi
fi
}


#Starting json out
echo "{"

#Getting AzureVMName
echo "    \"AzureVMName\": \"$vm\","

#Getting Subscription
echo "    \"Subscription\": \"$subs\","

#Getting ResourceGroup
echo "    \"ResourceGroup\": \"$rsg\","

#Getting Hostname of the machine
hostname=\"`hostname`\"
echo "    \"LocalVMName\": $hostname,"

#Getting IP
IP=\"`ip addr show eth0 | grep -Po 'inet \K[\d.]+'`\"
echo "    \"IP\": $IP,"

#Getting currently running linux kernal
#running_kernel=\"`uname -r`\"
#echo "    \"kernel\": $running_kernel,"

#Getting DNS server IPs"
dnsserver=\"`grep nameserver /etc/resolv.conf | awk  '{print $2}' | tr '\n' ' '`\"
echo "    \"DNSServerIP\": $dnsserver,"

#Getting OS version
osversion="`grep PRETTY_NAME /etc/os-release | awk -v FS='=' '{print $2}'`"
echo "    \"OsVersion\": $osversion,"

#Getting CB service status
servicestatus CBService cbdaemon

#Getting Qualys service status
servicestatus QualysService qualys-cloud-agent

#Getting CWPIDSService service status
servicestatus CWPIDSService sisidsdaemon

#Getting CWPIPSService service status
servicestatus CWPIPSService sisipsdaemon

#URL check
for i in "${urllist[@]}"
do
 host=`echo $i | awk -v FS=, '{print $1}'`
 port=`echo $i | awk -v FS=, '{print $2}'`
 name=`echo $i | awk -v FS=, '{print $3}'`
 nslookup $host > /dev/null 2>&1
 if [ `echo $?` != 0 ];then
  echo "    \"$name\": \"DNS Resolution Issue\","
 elif command -v nc &> /dev/null ; then
  nc -z $host $port > /dev/null 2>&1
  check=`echo $?`
  if [ $check == '0' ]; then 
     echo "    \"$name\": \"OK\","
  else
    echo "    \"$name\": \"Port Blocked\","
  fi
 elif command -v telnet &> /dev/null ; then
 # nc -z $host $port > /dev/null 2>&1
  check=`sleep 1| telnet $host $port  2>&1| grep "Escape character is" | wc -l`
  if [ `echo $check` == 1 ]; then
   echo "    \"$name\": \"OK\","
  else
   echo "    \"$name\": \"Port Blocked\","
  fi
 elif command -v curl &> /dev/null ; then
  check=`curl -vvv  -s --max-time 10  $host:$port  2>&1 | grep Connected | wc -l`
  if [ `echo $check` == 1 ]; then
   echo "    \"$name\": \"OK\","
  else
   echo "    \"$name\": \"Port Blocked\","
  fi

 else
   echo "    \"$name\": \"telnet or nc or curl command not found\","
 fi
done

#Getting currently running linux kernal
running_kernel=\"`uname -r`\"
echo "    \"kernel\": $running_kernel,"

#Getting vm uptime
up_time=\"`uptime | awk '{print $3" "$4}' | tr -d  ,`\"
echo "    \"Uptime_days\": $up_time"

echo "}"


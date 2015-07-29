#! /bin/bash
#===============================================================================================
#   Description: Test script for Aliyun ECS. include unixbench\bonnie++\iperf
#   Author: Ben  
#   Intro:  
#===============================================================================================
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

help()
{
   cat << HELP
   This is a benchmarks test sheel for aliyun ECS.
   USAGE EXAMPLE: 
   ./ecstest -i ,install the benchmarks;
   ./ecstest -d ,delete the last data;
   ./ecstest -nc "255.255.255.255" , set this machine as a iperf client,and the server ip is $2
   ./ecstest -ns ,set this machine as a iperf server,
HELP
   exit 0
}
opt=o
ip="112.124.102.169"  
marktime=`date +%Y%m%d%H%M`
while [ -n "$1" ]; do
case "$1" in
   -h) help;shift 1;; # function help is called
   -d) opt=d;shift 1;; 
   -i) opt=i;shift 1;; 
   -t) opt=t;shift 1;; 
   -nc) iperfopt=nc;ip=$2;opt=n;shift 2;;#set this machine as a iperf client,and the server ip is $2
   -ns) iperfopt=ns;opt=n;shift 1;;#set this machine as a iperf server,
   --) shift;break;; # end of options
   -*) echo "error: no such option $1. -h for help";exit 1;;
   *) break;; # run all script;
esac
done

if [ $opt=i ||  $opt=o ] ; then
   echo "install the benchmarks";
   # Update the system
apt-get -y update
apt-get -y upgrade
#install curl for save file to OSS online;
apt-get -y install curl

apt-get -y install iperf

# install bonnie++  http://mirrors.aliyun.com/ubuntu/ trusty/main bonnie++ amd64 1.97.1
apt-get -y install bonnie++

#yum -y install gcc gcc-c autoconf gcc-c++ time perl-Time-HiRes

# Create new soft download dir
mkdir -p /opt/unixbench;
cd /opt/unixbench;
cur_dir=`pwd`

# Download UnixBench5.1.3
if [ -s UnixBench5.1.3.tgz ]; then
    echo "UnixBench5.1.3.tgz [found]"
else
    echo "UnixBench5.1.3.tgz not found!!!download now......"
    if ! wget -c https://github.com/benxuu/benchmarks/raw/master/unixbench/UnixBench5.1.3.tgz;then
        echo "Failed to download UnixBench5.1.3.tgz,please download it to "${cur_dir}" directory manually and try again."
        exit 1
    fi
fi
tar -xzf UnixBench5.1.3.tgz;
cd UnixBench;
sed -i "s/GRAPHIC_TESTS = defined/#GRAPHIC_TESTS = defined/g" ./Makefile
make;
fi
 

if [ $opt=d ]; then
   echo "remove some test result file last time";
   rm /root/*.txt;
else
   echo "this is a new test begin!"


#cd $home;
if [ $opt=t  ||  $opt=o ] ; then
   echo "start run the benchmarks";
#Run unixbench
cd /opt/unixbench;
#echo $(date) >`hostname`-unixbench-${marktime}.txt
./Run >`hostname`-unixbench-${marktime}.txt
mv `hostname`-unixbench-${marktime}.txt /root

cd /root;
curl -T `hostname`-unixbench-${marktime}.txt http://aliyunbenchtest.oss-cn-hangzhou.aliyuncs.com


#Run bonnie++
mkdir /root/bonniedata
#echo $(date) >`hostname`-bonnie-${marktime}.txt
bonnie++ -d /root/bonniedata/ -u root -s 4096 -m $hostname >`hostname`-bonnie-${marktime}.txt
curl -T `hostname`-bonnie-${marktime}.txt http://aliyunbenchtest.oss-cn-hangzhou.aliyuncs.com
   
fi

#Run iperf
if [ $iperfopt=ns ] ;then
echo "set this machine to a iperf server"
iperf -s;
fi

if [ $iperfopt=nc ] ;then
#echo $(date) >$(hostname).iperf.txt
iperf -c $ip >`hostname`-iperf-${marktime}.txt
curl -T `hostname`-iperf-${marktime}.txt http://aliyunbenchtest.oss-cn-hangzhou.aliyuncs.com
fi


 



echo "The test work is end, What are your want to do next?"
select var in "logonout" "reboot" "delete the test data" "Other"; do
  break;
done
echo "You have selected $var"

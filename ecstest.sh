#! /bin/bash
#===============================================================================================
#   Description: Test script for Aliyun ECS. include unixbench\bonnie++\iperf
#   Author: Ben  
#   Intro:  
#===============================================================================================
# Update the system
apt-get -y update
apt-get -y upgrade
#install curl for save file to OSS online;
apt-get -y install curl
apt-get -y install iperf
#yum -y install gcc gcc-c autoconf gcc-c++ time perl-Time-HiRes

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
hostname=$(hostname)
export PATH

# install bonnie++  http://mirrors.aliyun.com/ubuntu/ trusty/main bonnie++ amd64 1.97.1
apt-get -y install bonnie++


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

cd $home;

#Run unixbench
echo $(date) >$(hostname).unixbench.txt
./Run >>$(hostname).unixbench.txt
curl -T $(hostname).unixbench.txt http://aliyunbenchtest.oss-cn-hangzhou.aliyuncs.com

#Run bonnie++
mkdir /root/bonniedata
echo $(date) >$(hostname).bonnie.txt
bonnie++ -d /root/bonniedata/ -u root -s 4096 -m $hostname >>$hostname.bonnie.txt
curl -T $(hostname).bonnie.txt http://aliyunbenchtest.oss-cn-hangzhou.aliyuncs.com

#Run iperf
echo $(date) >$(hostname).iperf.txt
iperf -c 112.124.102.169 >>$(hostname).iperf.txt
curl -T $(hostname).iperf.txt http://aliyunbenchtest.oss-cn-hangzhou.aliyuncs.com


echo '';
echo '';
echo '';
echo "======= Script description and score comparison completed! ======= ";
echo '';
echo '';
echo '';

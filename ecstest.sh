#! /bin/bash
#===============================================================================================
#   Description: Test script for Aliyun ECS. include unixbench\bonnie++\iperf
#   Author: Ben  
#   Intro:  
#===============================================================================================
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

mkdir /root/bonniedata
ip="112.124.102.169"  
marktime=`date +%Y%m%d%H%M`
opt=o
iperfopt=ns

help()
{
   cat << HELP
   This is a benchmarks test sheel for aliyun ECS.
   USAGE EXAMPLE: 
   ./ecstest  install and run benchmarks,except the iperf;
   ./ecstest -i ,only install the benchmarks,don't run;
   ./ecstest -r ,only do run the benchmarks, do test work,don't install again;
   ./ecstest -nc "255.255.255.255" , set this machine as a iperf client,and the server ip is $2
   ./ecstest -ns ,set this machine as a iperf server,
HELP
   exit 0
}


while [ -n "$1" ]; do
case "$1" in
   -h) help;shift 1;; # function help is called
   -d) opt=d;shift 1;; 
   -i) opt=i;shift 1;; 
   -r) opt=r;shift 1;; 
   -nc) iperfopt=nc;ip=$2;shift 2;;#set this machine as a iperf client,and the server ip is $2
   --) shift;break;; # end of options
   -*) echo "error: no such option $1. -h for help";exit 1;;
   *) break;; # run all script;
esac
done


if [[ $opt = i ]] || [[ $opt = o ]] ; then
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
    #if ! wget -c https://github.com/benxuu/benchmarks/raw/master/unixbench/UnixBench5.1.3.tgz;then
	if ! wget -c http://aliyunbenchtest.oss-cn-hangzhou.aliyuncs.com/UnixBench5.1.3.tgz;then
        echo "Failed to download UnixBench5.1.3.tgz,please download it to "${cur_dir}" directory manually and try again."
        exit 1
    fi
fi
tar -xzf UnixBench5.1.3.tgz;
cd UnixBench;
sed -i "s/GRAPHIC_TESTS = defined/#GRAPHIC_TESTS = defined/g" ./Makefile
make;
fi

#如果仅安装程序，则此时终止脚本
if [[ $opt = i ]] ; then
exit 0
fi



cd /root
echo `date` > `hostname`_testlog.txt	#日志记录
echo "机器名,日期时间,目标IP,带宽,单位" > `hostname`_iperf.csv	#定义iperf测试结果数据格式；
echo "机器名,日期时间,Dhrystone,Whetstone,Execl Throughput,FC1024, FC256,FC4096,Pipe Throughput,Pipe-based CS,Process Creation,Shell Scripts1,Shell Scripts8,System Call Overhead,SBIS" > `hostname`_unixbench.csv	#定义iperf测试结果数据格式；
echo "日期时间,机器名,,,SOPC,,SOB,,SOR,,SIPC,,SIB,,RC,,SCC" > `hostname`_bonnie.csv	#定义bonnie测试结果数据格式；

n,d,4G,,452,97,34541,5,27238,5,1011,90,62433,7,1118,21,16,,,,,32631,53,+++++,+++,+++++,+++,+++++,+++,+++++,+++,+++++,+++,22190us,799ms,1116ms,229ms,574ms,341ms,532us,488us,757us,313us,55us,387us
echo "set this machine to be a iperf server background"
iperf -s >> `hostname`_testlog.txt&
echo "set this machine to be a iperf server success"

while [ 1 = 1 ]; do #start the test loop


echo "run iperf as client to test network with_"$ip
iperfvar=`iperf -c $ip`	# >`hostname`-iperf-${marktime}.txt
echo $iperfvar >> `hostname`_testlog.txt
#echo "run iperf as client to test network with_"$ip >>`hostname`_testdata.txt

iperfvar=${iperfvar##*Bytes}
echo `hostname`,$ip,`date`,${iperfvar% *},${iperfvar#* } >> `hostname`_iperf.csv	#记录数据

#curl -T `hostname`-iperf-${marktime}.txt http://aliyunbenchtest.oss-cn-hangzhou.aliyuncs.com


#cd $home;
#Run unixbench
echo "start run the unixbench";

cd /opt/unixbench/UnixBench/
./Run >/root/unixbenchvar.txt
#ubvar=`./Run`
#mv `hostname`-unixbench-${marktime}.txt /root
cd /root
echo `date` >> `hostname`_testlog.txt
cat unixbenchvar.txt >> `hostname`_testlog.txt

#echo "The result of unixbench test,1:Double-Precision Whetstone 2:File Copy 1024 bufsize 2000 maxblocks 3:File Copy 256 bufsize 500 maxblocks  4:File Copy 4096 bufsize 8000 maxblocks">> `hostname`_testdata.txt	#记录时间
#echo "unixbench--"`date` >> `hostname`_testdata.txt	#记录时间
#echo "机器名,日期时间,Dhrystone,Whetstone,Execl Throughput,FC1024, FC256,FC4096,Pipe Throughput,Pipe-based CS,Process Creation,Shell Scripts1,Shell Scripts8,System Call Overhead,SBIS" > `hostname`_unixbench.csv	#定义iperf测试结果数据格式；

dataStr=`hostname`,`date`
while read LINE
do
if [[ $$LINE == Dhrystone*lps* ]] ; then
LINE=${LINE##*variables}
dataStr+=,${LINE%%lps*}
else if [[ $LINE == *MWIPS*  ]] ; then
LINE=${LINE##*Whetstone}
dataStr+=,${LINE%%MWIPS*}
else if [[ $LINE == Execl*lps*  ]] ; then
LINE=${LINE##*Throughput}
dataStr+=,${LINE%%lps*}
else if [[ $LINE == "File Copy 1024"*KBps*  ]] ; then
LINE=${LINE##*maxblocks}
dataStr+=,${LINE%%KBps*}
else if [[ $LINE == "File Copy 256"*KBps*  ]] ; then
LINE=${LINE##*maxblocks}
dataStr+=,${LINE%%KBps*}
else if [[ $LINE == "File Copy 4096"*KBps*  ]] ; then
LINE=${LINE##*maxblocks}
dataStr+=,${LINE%%KBps*}
else if [[ $LINE == "Pipe Throughput"*lps*  ]] ; then
LINE=${LINE##*Throughput}
dataStr+=,${LINE%%lps*}
else if [[ $LINE == "Pipe-based Context Switching "*lps*  ]] ; then
LINE=${LINE##*Switching}
dataStr+=,${LINE%%lps*}
else if [[ $LINE == "Process Creation "*lps*  ]] ; then
LINE=${LINE##*Creation}
dataStr+=,${LINE%%lps*}
else if [[ $LINE == "Shell Scripts (1 concurrent)"*lpm*  ]] ; then
LINE=${LINE##*concurrent)}
dataStr+=,${LINE%%lpm*}
else if [[ $LINE == "Shell Scripts (8 concurrent)"*lpm*  ]] ; then
LINE=${LINE##*concurrent)}
dataStr+=,${LINE%%lpm*}
else if [[ $LINE == "System Call Overhead"*lps*  ]] ; then
LINE=${LINE##*Overhead)}
dataStr+=,${LINE%%lps*}
else if [[ $LINE == "System Benchmarks Index Score"* ]] ; then
LINE=${LINE##*Score)}
dataStr+=,${LINE}
fi
fi
fi
fi
fi
fi
fi
fi
fi
fi
fi
fi
fi
done < unixbenchvar.txt
echo  $dataStr >> `hostname`_unixbench.csv	#记录数据	 
#curl -T `hostname`-unixbench-${marktime}.txt http://aliyunbenchtest.oss-cn-hangzhou.aliyuncs.com


#Run bonnie++
echo "start run the bonnie++";
bonnie++ -d /root/bonniedata/ -u root -s 4096 -m `hostname` > bonnievar.txt

cat bonnievar.txt >> `hostname`_testlog.txt

#echo "The result of bonnie++ test: 1:Sequential Input Per Chr 2:Block 3:Random seeks" >> `hostname`_testdata.txt
#echo "bonnie++--"`date` >> `hostname`_testdata.txt	#记录时间
while read LINE
do
if [[ $LINE == *1.97,* ]] ; then
#echo "日期时间,机器名,,,SOPC,,SOB,,SOR,,SIPC,,SIB,,RC,,SCC" > `hostname`_bonnie.csv
echo `date`${LINE#*1.97,1.97} >> `hostname`_bonnie.csv
#b1=${LINE%%,*}
#LINE=${LINE#*,*,}
#b2=${LINE%%,*}
#LINE=${LINE#*,*,}
#b3=${LINE%%,*}
#echo $b1 >>`hostname`_testdata.txt;
#echo $b2 >>`hostname`_testdata.txt;
#echo $b3 >>`hostname`_testdata.txt;
fi
done <  bonnievar.txt
#echo  >> `hostname`_testdata.txt	#换行
#每次循环上传一次结果
curl -T `hostname`_testdata.txt http://aliyunbenchtest.oss-cn-hangzhou.aliyuncs.com 
curl -T `hostname`_iperf.csv http://aliyunbenchtest.oss-cn-hangzhou.aliyuncs.com 
curl -T `hostname`_unixbench.csv http://aliyunbenchtest.oss-cn-hangzhou.aliyuncs.com 
curl -T `hostname`_bonnie.csv http://aliyunbenchtest.oss-cn-hangzhou.aliyuncs.com 
done


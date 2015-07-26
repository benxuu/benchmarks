# This script is FREE and written by www.ctohome.com


# Create new soft download dir
mkdir -p /backup/www.ctohome.com;
cd /backup/www.ctohome.com;


# Download unixbench
wget http://www.ctohome.com/linux-vps-pack/unixbench-5.1.2.tar.gz;
tar xzf unixbench-5.1.2.tar.gz;
cd unixbench-5.1.2;

yum -y install gcc gcc-c autoconf gcc-c++ time

#Run unixbench
sed -i "s/GRAPHIC_TESTS = defined/#GRAPHIC_TESTS = defined/g" ./Makefile
make;
./Run;



echo '';
echo '';
echo '';

echo "======= Script description and score comparison: ======= ";
echo '';
echo 'http://www.ctohome.com/FuWuQi/c5/172.html';
echo '';
echo '';





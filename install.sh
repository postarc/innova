#!/bin/bash

COIN='https://github.com/innovacoin/innova/releases/download/12.1.10/linux_x64.tar.gz'
RPCPORT=14519
PORT=14520

sudo apt-get update -y
mkdir ~/innova
mkdir ~/.innovacore
cd ~/innova
wget $COIN
tar xvzf linux_x64.tar.gz
if [ ! -f "/usr/local/bin/innovad" ]; then
	echo -e "\e[32mCopying bin files...\e[0m"
	sudo cp innova* /usr/local/bin
	sudo chown -R root:users /usr/local/bin
else
	echo -e "\e[31mBin files exist. Skipping copy...\e[0m"
fi

sudo apt-get install -y pwgen

# writing innova.conf file:
echo -e "\e[32mWriting innova config file...\e[0m"
while [ -n "$(sudo lsof -i -s TCP:LISTEN -P -n | grep $RPCPORT)" ]
do
(( RPCPORT--))
done
echo -e "\e[32mFree RPCPORT address:$RPCPORT\e[0m"
while [ -n "$(sudo lsof -i -s TCP:LISTEN -P -n | grep $PORT)" ]
do
(( PORT++))
done
echo -e "\e[32mFree MN port address:$PORT\e[0m"
NODEIP=$(curl -s4 icanhazip.com)
GEN_PASS=`pwgen -1 20 -n`
echo -e "rpcuser=innovauser\nrpcpassword=${GEN_PASS}\nrpcport=$RPCPORT\nexternalip=$NODEIP:14520\nport=$PORT\nlisten=1\nmaxconnections=256" > ~/.innovacore/innova.conf
# set masternodeprivkey
#cd ~/innova

innovad -daemon
sleep 15
MASTERNODEKEY=$(./innova-cli masternode genkey)
if [ "$?" -gt "0" ];
    then
    echo -e "\e[32mWallet not fully loaded. Let us wait and try again to generate the Private Key\e[0m"
    sleep 15
    MASTERNODEKEY=$(./innova-cli masternode genkey)
fi
innova-cli stop
echo -e "masternode=1\nmasternodeprivkey=$MASTERNODEKEY\n" >> ~/.innovacore/innova.conf
echo -e "addnode=explorer.innovacoin.info\n" >>  ~/.innovacore/innova.conf
echo -e "addnode=80.209.228.34\naddnode=115.68.231.108\naddnode=140.82.52.186\naddnode=185.174.172.23\naddnode=80.211.184.193\naddnode=173.255.245.85\naddnode=206.189.171.73\naddnode=167.88.171.147\naddnode=80.211.80.95\naddnode=167.99.136.116\naddnode=45.76.90.228\naddnode=80.211.189.170\naddnode=108.61.123.204\naddnode=185.81.166.71\naddnode=82.146.41.42\naddnode=173.249.49.234\naddnode=207.246.67.150\naddnode=194.182.82.247\naddnode=95.216.139.46\naddnode=199.247.3.245\naddnode=45.77.74.167\naddnode=95.179.134.202\naddnode=80.211.19.158\naddnode=149.28.102.107\naddnode=80.211.61.184\naddnode=207.246.106.216\naddnode=185.53.169.254\naddnode=185.219.83.198\naddnode=95.216.159.18\naddnode=104.238.177.142\naddnode=80.211.57.222\naddnode=183.88.252.88\naddnode=209.250.255.223\naddnode=217.163.28.135\naddnode=80.211.96.186\naddnode=50.3.69.111\naddnode=185.189.14.118\naddnode=148.163.101.126\naddnode=51.15.232.206\naddnode=140.82.38.197\naddnode=207.148.16.76\naddnode=94.176.234.97\naddnode=185.92.223.98\naddnode=46.33.231.249\naddnode=45.32.232.107\naddnode=94.158.36.89\naddnode=185.61.150.76\naddnode=80.209.238.30\naddnode=199.247.20.135\naddnode=199.247.3.62\naddnode=144.202.65.246\naddnode=80.211.76.37\naddnode=139.99.97.65\naddnode=193.77.82.149">> ~/.innovacore/innova.conf

# installing SENTINEL
echo -e "\e[32mStart Sentinel installing process...\e[0m"
cd ~/.innovacore
sudo apt-get install -y git python-virtualenv
git clone https://github.com/innovacoin/sentinel.git
cd sentinel
export LC_ALL=C
sudo apt-get install -y virtualenv
virtualenv venv
venv/bin/pip install -r requirements.txt
echo "innova_conf=/home/$USER/.innovacore/innova.conf" >> sentinel.conf

# get mnchecker
cd ~
git clone https://github.com/innovacointeam/mnchecker ~/mnchecker
# setup cron
crontab -l > tempcron
echo "@reboot /usr/local/bin/innovad -daemon" > tempcron
echo "* * * * * cd ~/.innovacore/sentinel && ./venv/bin/python bin/sentinel.py 2>&1 >> sentinel-cron.log" >> tempcron
echo "*/30 * * * * ~/mnchecker/mnchecker --currency-handle=\"innova\" --currency-bin-cli=\"innova-cli\" --currency-datadir=\"~/.innovacore\" > ~/mnchecker/mnchecker-cron.log 2>&1" >> tempcron
crontab tempcron

chmod +x ~/.innovacore/sentinel/bin/*.py
rm tempcron
rm -rf ~/innova
rm -rf innovascript
echo -e "\e[32mVPS ip: $NODEIP\e[0m"
echo -e "\e[32mMasternode private key: $MASTERNODEKEY\e[0m"
echo -e "\e[32mJob completed successfully\e[0m"

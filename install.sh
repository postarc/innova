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
sleep 17
MASTERNODEKEY=$(./innova-cli masternode genkey)
echo -e "masternode=1\nmasternodeprivkey=$MASTERNODEKEY\n" >> ~/.innovacore/innova.conf
echo "addnode=explorer.innovacoin.info\n" >>  ~/.innovacore/innova.conf
innova-cli stop

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

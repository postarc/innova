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
	echo "Copying bin files...."
	cp innova* /usr/local/bin
	sudo crown -R root:users /usr/local/bin
else
	echo "Bin files exist. Skipping copy..."
fi

sudo apt-get install -y pwgen

# writing innova.conf file:
echo "Writing innova config file..."
while [ -n "$(sudo lsof -i -s TCP:LISTEN -P -n | grep $RPCPORT)" ]
do
(( RPCPORT--))
done
echo "Free RPCPORT address:$RPCPORT"
while [ -n "$(sudo lsof -i -s TCP:LISTEN -P -n | grep $PORT)" ]
do
(( PORT++))
done
echo "Free MN port address:$PORT"
NODEIP=$(curl -s4 icanhazip.com)
GEN_PASS=`pwgen -1 20 -n`
echo -e "rpcuser=innovauser\nrpcpassword=${GEN_PASS}\nrpcport=$RPCPORT\nexternalip=$NODEIP:14520\nport=$PORT\nlisten=1\nmaxconnections=256" > ~/.innovacore/innova.conf
# set masternodeprivkey
#cd ~/innova
innovad -daemon
sleep 15
MASTERNODEKEY=$(./innova-cli masternode genkey)
echo -e "masternode=1\nmasternodeprivkey=$MASTERNODEKEY" >> ~/.innovacore/innova.conf
innova-cli stop

# installing SENTINEL
echo "Start Sentinel installing process..."
cd ~/.innovacore
sudo apt-get install -y git python-virtualenv
git clone https://github.com/innovacoin/sentinel.git
cd sentinel
export LC_ALL=C
sudo apt-get install -y virtualenv
virtualenv venv
venv/bin/pip install -r requirements.txt

# get mnchecker
cd ~
git clone https://github.com/innovacointeam/mnchecker ~/mnchecker
# setup cron
crontab -l > tempcron
echo "@reboot /usr/local/bin/innovad -daemon" > tempcron
echo "* * * * * cd ~/.innovacore/sentinel && ./venv/bin/python bin/sentinel.py 2>&1 >> sentinel-cron.log" >> tempcron
echo "*/30 * * * * ~/mnchecker/mnchecker --currency-handle=\"innova\" --currency-bin-cli=\"innova-cli\" --currency-datadir=\"~/.innovacore\" > ~/mnchecker/mnchecker-cron.log 2>&1" >> tempcron
crontab tempcron

rm tempcron
rm -rf ~/innova
innovad -daemon
echo "VPS ip: $NODEIP"
echo "Masternode private key: $MASTERNODEKEY"
echo "Job completed successfully"

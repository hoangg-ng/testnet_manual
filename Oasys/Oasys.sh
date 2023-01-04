#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1 

echo -e "\033[0;35m"

echo " ▄▄▄       ██▓     ██▓███   ██░ ██  ▄▄▄       ██▓    ▓█████ ██▒   █▓▓█████  ██▀███   ▄▄▄        ▄████ ▓█████ ";
echo "▒████▄    ▓██▒    ▓██░  ██▒▓██░ ██▒▒████▄    ▓██▒    ▓█   ▀▓██░   █▒▓█   ▀ ▓██ ▒ ██▒▒████▄     ██▒ ▀█▒▓█   ▀ ";
echo "▒██  ▀█▄  ▒██░    ▓██░ ██▓▒▒██▀▀██░▒██  ▀█▄  ▒██░    ▒███   ▓██  █▒░▒███   ▓██ ░▄█ ▒▒██  ▀█▄  ▒██░▄▄▄░▒███   ";
echo "░██▄▄▄▄██ ▒██░    ▒██▄█▓▒ ▒░▓█ ░██ ░██▄▄▄▄██ ▒██░    ▒▓█  ▄  ▒██ █░░▒▓█  ▄ ▒██▀▀█▄  ░██▄▄▄▄██ ░▓█  ██▓▒▓█  ▄ ";
echo " ▓█   ▓██▒░██████▒▒██▒ ░  ░░▓█▒░██▓ ▓█   ▓██▒░██████▒░▒████▒  ▒▀█░  ░▒████▒░██▓ ▒██▒ ▓█   ▓██▒░▒▓███▀▒░▒████▒";
echo " ▒▒   ▓▒█░░ ▒░▓  ░▒▓▒░ ░  ░ ▒ ░░▒░▒ ▒▒   ▓▒█░░ ▒░▓  ░░░ ▒░ ░  ░ ▐░  ░░ ▒░ ░░ ▒▓ ░▒▓░ ▒▒   ▓▒█░ ░▒   ▒ ░░ ▒░ ░";
echo "  ▒   ▒▒ ░░ ░ ▒  ░░▒ ░      ▒ ░▒░ ░  ▒   ▒▒ ░░ ░ ▒  ░ ░ ░  ░  ░ ░░   ░ ░  ░  ░▒ ░ ▒░  ▒   ▒▒ ░  ░   ░  ░ ░  ░";
echo "  ░   ▒     ░ ░   ░░        ░  ░░ ░  ░   ▒     ░ ░      ░       ░░     ░     ░░   ░   ░   ▒   ░ ░   ░    ░   ";
echo "      ░  ░    ░  ░          ░  ░  ░      ░  ░    ░  ░   ░  ░     ░     ░  ░   ░           ░  ░      ░    ░  ░";
echo "                                                                ░                                            ";
echo "                                                                                                             ";
echo "                                                                                                             ";
echo "                                                                                                             ";
echo -e "\e[0m"
sleep 3

sudo useradd -s /sbin/nologin geth
sudo rm -rf /home/geth
sudo mkdir -p /home/geth/.ethereum/geth/
sudo chown -R geth:geth /home/geth
sudo chmod -R 700 /home/geth
if [ ! $PASS ]; then
read -p "Enter a new password for your account: " PASS
echo $PASS > /home/geth/.ethereum/password.txt
fi
echo -e '\n\e[42mInstall software\e[0m\n' && sleep 1
apt update && apt install unzip sudo -y < "/dev/null"
cd $HOME
wget -O geth-linux-amd64.zip https://github.com/oasysgames/oasys-validator/releases/download/v1.0.3/geth-v1.0.3-linux-amd64.zip
unzip geth-linux-amd64.zip
sudo mv geth /usr/local/bin/geth
wget -O genesis.zip https://github.com/oasysgames/oasys-validator/releases/download/v1.0.3/genesis.zip
unzip genesis.zip
mv genesis/testnet.json /home/geth/genesis.json
sudo -u geth geth init /home/geth/genesis.json
echo '[ "enode://4a85df39ec500acd31d4b9feeea1d024afee5e8df4bc29325c2abf2e0a02a34f6ece24aca06cb5027675c167ecf95a9fc23fb7a0f671f84edb07dafe6e729856@35.77.156.6:30303" ]' > /home/geth/.ethereum/geth/static-nodes.json

sudo -u geth geth account new --password "/home/geth/.ethereum/password.txt" >/home/geth/.ethereum/wallet.txt
OASYS_ADDRESS=$(grep -a "Public address of the key: " /home/geth/.ethereum/wallet.txt | sed -r 's/Public address of the key:   //')

# export NETWORK_ID=248
#export NETWORK_ID=9372
#export OASYS_ADDRESS="0xc3f3e1Fc51Fa86e4125712B4E838d8E910982503"
  
echo "[Unit]
Description=Oasys Node
After=network.target

[Service]
User=geth
Type=simple
ExecStart=$(which geth) \
 --networkid 9372 \
 --syncmode full --gcmode archive \
 --mine --miner.gaslimit 30000000 \
 --allow-insecure-unlock \
 --unlock $OASYS_ADDRESS \
 --password /home/geth/.ethereum/password.txt \
 --http --http.addr 0.0.0.0 --http.port 8545 \
 --http.vhosts '*' --http.corsdomain '*' \
 --http.api net,eth,web3 \
 --snapshot=false
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/oasysd.service
sudo mv $HOME/oasysd.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable oasysd
sudo systemctl restart oasysd
echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service oasysd status | grep active` =~ "running" ]]; then
  echo -e "Your Oasys node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mservice oasysd status\e[0m"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
else
  echo -e "Your Oasys node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
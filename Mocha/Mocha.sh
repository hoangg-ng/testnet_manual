#!/bin/bash

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
sleep 2

read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="mocha"
CHAIN_DENOM="utia"
BINARY_NAME="celestia-appd"
BINARY_VERSION_TAG="v0.11.1"
CHEAT_SHEET="https://nodejumper.io/mocha-testnet/cheat-sheet"

printLine
echo -e "Node moniker:       ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:           ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:        ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag: ${CYAN}$BINARY_VERSION_TAG${NC}"
printLine
sleep 1

source <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-scripts/master/utils/dependencies_install.sh)

printCyan "4. Building binaries..." && sleep 1

cd $HOME || return
rm -rf celestia-app
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app || return
git checkout v0.11.1
make install
celestia-appd version # 0.11.

celestia-appd config keyring-backend test
celestia-appd config chain-id $CHAIN_ID
celestia-appd init "$NODE_MONIKER" --chain-id $CHAIN_ID

curl -s https://raw.githubusercontent.com/celestiaorg/networks/master/mocha/genesis.json > $HOME/.celestia-app/config/genesis.json
curl -s https://snapshots3-testnet.nodejumper.io/celestia-testnet/addrbook.json > $HOME/.celestia-app/config/addrbook.json

SEEDS=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mocha/seeds.txt | tr -d '\n')
PEERS=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mocha/peers.txt | tr -d '\n')
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.celestia-app/config/config.toml

PRUNING_INTERVAL=$(shuf -n1 -e 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97)
sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.celestia-app/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.celestia-app/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "'$PRUNING_INTERVAL'"|g' $HOME/.celestia-app/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 2000|g' $HOME/.celestia-app/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001utia"|g' $HOME/.celestia-app/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.celestia-app/config/config.toml

printCyan "5. Starting service and synchronization..." && sleep 1

sudo tee /etc/systemd/system/celestia-appd.service > /dev/null << EOF
[Unit]
Description=Celestia Validator Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which celestia-appd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app --keep-addr-book

SNAP_NAME=$(curl -s https://snapshots3-testnet.nodejumper.io/celestia-testnet/ | egrep -o ">mocha.*\.tar.lz4" | tr -d ">")
curl https://snapshots3-testnet.nodejumper.io/celestia-testnet/${SNAP_NAME} | lz4 -dc - | tar -xf - -C $HOME/.celestia-app

sudo systemctl daemon-reload
sudo systemctl enable celestia-appd
sudo systemctl start celestia-appd

printLine
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "More commands:         ${CYAN}$CHEAT_SHEET${NC}
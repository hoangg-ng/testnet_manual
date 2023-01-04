#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/ZerexVnZ/humanai/main/common.sh)

printCyan "1. Updating packages..." && sleep 1
sudo apt update

printCyan "2. Installing dependencies..." && sleep 1
sudo apt install -y make gcc jq curl git lz4 build-essential chrony unzip

printCyan "3. Installing go..." && sleep 1
if [ ! -f "/usr/local/go/bin/go" ]; then
  source <(curl -s "https://raw.githubusercontent.com/ZerexVnZ/humanai/main/go_install.sh")
  source .bash_profile
fi

echo "$(go version)"
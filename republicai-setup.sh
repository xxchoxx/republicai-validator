#!/bin/bash

echo -e "
          \033[38;5;51m \033[38;5;45m \033[38;5;39m \033[38;5;33m \033[38;5;27m \033[38;5;57m \033[38;5;93m_\033[38;5;129m \033[38;5;165m \033[38;5;197m \033[38;5;196m \033[38;5;202m \033[38;5;208m \033[38;5;220m \033[38;5;226m \033[38;5;190m \033[38;5;154m \033[38;5;82m \033[38;5;46m \033[38;5;47m \033[38;5;48m \033[38;5;50m \033[0m
          \033[38;5;51m_\033[38;5;45m_\033[38;5;39m \033[38;5;33m \033[38;5;27m_\033[38;5;57m|\033[38;5;93m \033[38;5;129m|\033[38;5;165m_\033[38;5;197m_\033[38;5;196m \033[38;5;202m \033[38;5;208m \033[38;5;220m_\033[38;5;226m_\033[38;5;190m_\033[38;5;154m \033[38;5;82m_\033[38;5;46m_\033[38;5;47m_\033[38;5;48m \033[38;5;50m \033[0m
          \033[38;5;51m\\\\\033[38;5;45m \033[38;5;39m\\\\\033[38;5;33m/\033[38;5;27m \033[38;5;57m/\033[38;5;93m \033[38;5;129m'\033[38;5;165m_\033[38;5;197m \033[38;5;196m\\\\\033[38;5;202m \033[38;5;208m/\033[38;5;220m \033[38;5;226m_\033[38;5;190m_\033[38;5;154m/\033[38;5;82m \033[38;5;46m_\033[38;5;47m \033[38;5;48m\\\\\033[38;5;50m \033[0m
          \033[38;5;51m \033[38;5;45m>\033[38;5;39m \033[38;5;33m \033[38;5;27m<\033[38;5;57m|\033[38;5;93m \033[38;5;129m|\033[38;5;165m \033[38;5;197m|\033[38;5;196m \033[38;5;202m|\033[38;5;208m \033[38;5;220m(\033[38;5;226m_\033[38;5;190m|\033[38;5;154m \033[38;5;82m(\033[38;5;46m_\033[38;5;47m)\033[38;5;48m \033[38;5;50m|\033[0m
          \033[38;5;51m/\033[38;5;45m_\033[38;5;39m/\033[38;5;33m\\\\\033[38;5;27m_\033[38;5;57m\\\\\033[38;5;93m_\033[38;5;129m|\033[38;5;165m \033[38;5;197m|\033[38;5;196m_\033[38;5;202m|\033[38;5;208m\\\\\033[38;5;220m_\033[38;5;226m_\033[38;5;190m_\033[38;5;154m\\\\\033[38;5;82m_\033[38;5;46m_\033[38;5;47m_\033[38;5;48m/\033[38;5;50m \033[0m
     \033[38;5;51m-\033[38;5;51m-\033[38;5;45m-\033[38;5;39m-\033[38;5;33m-\033[38;5;27m \033[38;5;21mb\033[38;5;57me\033[38;5;57mt\033[38;5;93mt\033[38;5;129me\033[38;5;165mr\033[38;5;201m \033[38;5;197mc\033[38;5;196ma\033[38;5;202ml\033[38;5;202ml\033[38;5;208m \033[38;5;214mm\033[38;5;220me\033[38;5;226m \033[38;5;190mx\033[38;5;154mh\033[38;5;154mc\033[38;5;118mo\033[38;5;82m \033[38;5;46m-\033[38;5;47m-\033[38;5;48m-\033[38;5;49m-\033[38;5;50m-\033[0m"
echo

# RepublicAI Validator Setup Script (Systemd)
# Version: v0.2.0
# Compatible with: Ubuntu 22.04

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE} RepublicAI Validator Setup (Systemd) ${NC}"
echo -e "${BLUE}==========================================${NC}"
echo -e "${YELLOW}Version: v0.2.0${NC}"
echo -e "${YELLOW}Chain ID: raitestnet_77701-1${NC}"
echo

# Function to check for errors
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: $1${NC}"
        exit 1
    fi
}

# Prompt for moniker input
read -p "Enter moniker for your validator: " MONIKER
if [ -z "$MONIKER" ]; then
    echo -e "${RED}Moniker cannot be empty!${NC}"
    exit 1
fi

# Update system
echo -e "${YELLOW}Updating system and installing dependencies...${NC}"
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl wget jq make git gcc ufw build-essential lz4

# Firewall configuration
echo -e "${YELLOW}Configuring firewall...${NC}"
sudo ufw allow 22/tcp
sudo ufw allow 26656/tcp
sudo ufw allow 26657/tcp
sudo ufw allow 1317/tcp
echo "y" | sudo ufw enable

# Go installation
echo -e "${YELLOW}Installing Go...${NC}"
GO_VERSION="1.21.6"
if ! command -v go &> /dev/null; then
    wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
    check_error "Failed to download Go"
    
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
    rm go${GO_VERSION}.linux-amd64.tar.gz
    
    echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> $HOME/.bashrc
    source $HOME/.bashrc
else
    echo -e "${GREEN}Go is already installed${NC}"
fi

# Verify Go installation
echo -e "${YELLOW}Verifying Go installation...${NC}"
GO_VER=$(go version | awk '{print $3}')
echo "Go version: $GO_VER"

# RepublicAI binary installation
echo -e "${YELLOW}Downloading and installing RepublicAI binary v0.2.0...${NC}"
BINARY_URL="https://github.com/RepublicAI/networks/releases/download/v0.2.0/republicd-linux-amd64 -O republicd"
wget $BINARY_URL
chmod +x republicd
sudo mv republicd /usr/local/bin/
check_error "Failed to download RepublicAI binary"
echo -e "${GREEN}RepublicAI binary installed successfully${NC}"

# Verify installation
echo -e "${YELLOW}Verifying RepublicAI installation...${NC}"
VERSION=$(republicd version 2>/dev/null || echo "Failed")
if [ "$VERSION" = "Failed" ]; then
    echo -e "${RED}Verification failed! RepublicAI is not installed correctly${NC}"
    exit 1
else
    echo -e "${GREEN}RepublicAI version: $VERSION${NC}"
fi

# Initialize node
echo -e "${YELLOW}Initializing node...${NC}"
republicd init "$MONIKER" --chain-id raitestnet_77701-1
check_error "Failed to initialize node"

# Download genesis file
echo -e "${YELLOW}Downloading genesis file...${NC}"
curl -s https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json > $HOME/.republic/config/genesis.json
check_error "Failed to download genesis file"

# Setup state sync
echo -e "${YELLOW}Configuring state sync...${NC}"
SNAP_RPC="https://statesync.republicai.io"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000))
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

sed -i.bak -E "s|^(enable *=).*|\1 true|; \
s|^(rpc_servers *=).*|\1 \"$SNAP_RPC,$SNAP_RPC\"|; \
s|^(trust_height *=).*|\1 $BLOCK_HEIGHT|; \
s|^(trust_hash *=).*|\1 \"$TRUST_HASH\"|" \
$HOME/.republic/config/config.toml
check_error "Failed to configure state sync"

# Setup peers
echo -e "${YELLOW}Configuring peers...${NC}"
PEERS="e281dc6e4ebf5e32fb7e6c4a111c06f02a1d4d62@3.92.139.74:26656,cfb2cb90a241f7e1c076a43954f0ee6d42794d04@54.173.6.183:26656,dc254b98cebd6383ed8cf2e766557e3d240100a9@54.227.57.160:26656"
sed -i.bak "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.republic/config/config.toml
check_error "Failed to configure peers"

# Optimize configuration
echo -e "${YELLOW}Optimizing configuration...${NC}"
sed -i 's/^indexer *=.*/indexer = "kv"/' $HOME/.republic/config/config.toml
sed -i 's/^pruning *=.*/pruning = "custom"/' $HOME/.republic/config/app.toml
sed -i 's/^pruning-keep-recent *=.*/pruning-keep-recent = "100"/' $HOME/.republic/config/app.toml
sed -i 's/^pruning-keep-every *=.*/pruning-keep-every = "0"/' $HOME/.republic/config/app.toml
sed -i 's/^pruning-interval *=.*/pruning-interval = "10"/' $HOME/.republic/config/app.toml
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "250000000arai"|' $HOME/.republic/config/app.toml

# Setup systemd service
echo -e "${YELLOW}Configuring systemd service...${NC}"
sudo tee /etc/systemd/system/republicd.service > /dev/null <<EOF
[Unit]
Description=RepublicAI Node
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/.republic
ExecStart=/usr/local/bin/republicd start --home $HOME/.republic
Restart=always
RestartSec=3
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.republic"
Environment="DAEMON_NAME=republicd"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"

[Install]
WantedBy=multi-user.target
EOF
check_error "Failed to create systemd service file"

# Enable and start service
echo -e "${YELLOW}Starting RepublicAI service...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable republicd
sudo systemctl start republicd
check_error "Failed to start RepublicAI service"

# Wait a moment for node to start
echo -e "${YELLOW}Waiting for node to start...${NC}"
sleep 10

# Display important information
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}RepublicAI installation successful!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo
echo -e "${BLUE}Next steps:${NC}"
echo "1. Wait for node to sync (check with: republicd status 2>&1 | jq '.sync_info')"
echo "2. Follow the wallet and validator creation guide below"
echo
echo -e "${BLUE}Important commands:${NC}"
echo "sudo systemctl status republicd    # Check service status"
echo "sudo journalctl -u republicd -f    # Monitor logs in real-time"
echo "republicd status 2>&1 | jq '.sync_info'  # Check sync status"
echo
echo -e "${BLUE}Node information:${NC}"
echo "Chain ID: raitestnet_77701-1"
echo "Moniker: $MONIKER"
echo "Home directory: $HOME/.republic"
echo
echo -e "${GREEN}Node is running in the background.${NC}"
echo -e "${GREEN}Please follow the guide below to create a wallet and validator.${NC}"

# RepublicAI Validator Setup Guide with Systemd

**A comprehensive guide to installing the RepublicAI Validator using systemd with version (v0.2.1)**

> **Important Note**: This guide uses a systemd installation and for who new installed version 0.2.1 or latest cuz in my guide directory new is .republic not .republicd (version 1), if you already istalled better use old guide.

## 📋 Table of Contents
- [System Requirements](#-system-requirements)
- [Automatic Installation](#-automatic-installation)
- [Installation Verification](#-installation-verification)
- [Wallet Creation](#-wallet-creation)
- [Validator Creation](#-validator-creation)
- [Important Commands](#-important-commands)
- [Backup and Recovery](#-backup-and-recovery)
- [Updating to a New Version](#-updating-to-a-new-version)
- [Troubleshooting](#-troubleshooting)
- [FAQ](#-faq)
- [References](#-references)

## 💻 System Requirements

Below are the minimum recommended VPS specifications for running the RepublicAI Validator:

| Component          | Minimum Specification |
| :----------------- | :-------------------- |
| **Operating System**| Ubuntu 22.04          |
| **CPU**            | 4 vCPU                |
| **RAM**            | 16 GB                 |
| **Storage**        | 300–500 GB SSD        |
| **Internet Connection**| Stable                |

## ⚡ Automatic Installation

### 1. Run the Installation Script

We provide an automatic script to simplify the installation. This script will perform the following actions:

- Update the system and install dependencies
- Install Go
- Download and install the RepublicAI binary
- Configure the node with state sync
- Create and activate the systemd service

```bash
wget -O republicai-setup.sh https://raw.githubusercontent.com/xxchoxx/republicai-validator/main/republicai-setup.sh && chmod +x republicai-setup.sh && ./republicai-setup.sh
```

## 🔍 Installation Verification

After running the script, verify that the node is running correctly:

```bash
# Check the service status
sudo systemctl status republicd

# Monitor logs in real-time
sudo journalctl -u republicd -f -o cat

# Check the sync status
republicd status 2>&1 | jq '.sync_info'
```

**Expected output:**
```json
{
  "latest_block_hash": "A1B2C3...",
  "latest_app_hash": "D4E5F6...",
  "latest_block_height": "123456",
  "latest_block_time": "2026-02-05T12:34:56.789Z",
  "earliest_block_height": "0",
  "earliest_block_hash": "000000...",
  "catching_up": false
}
```

> **Note**: Wait until `catching_up: false` before proceeding to the next steps. This process usually takes 5-15 minutes sometimes longer depending on the situation with state sync before next step.

## 🔐 Wallet Creation

### 1. Create a Validator Wallet

```bash
republicd keys add validator --home $HOME/.republic
```

> **IMPORTANT**: Securely save the seed phrase in a location separate from your server. You will need it to recover your wallet if any issues occur.

**Example output:**
```
- name: validator
  type: local
  address: rai1abc...xyz
  pubkey: '{"@type":"/cosmos.crypto.secp256k1.PubKey","key":"A1B2C3..."}'
  mnemonic: ""
  
**Important** write this mnemonic phrase in a safe place.
It is the only way to recover your account if you ever forget your password.

"word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12"
```

### 2. Verify Wallet Addresses

```bash
# Account address (for regular transactions)
republicd keys show validator -a --home $HOME/.republic

# Validator operator address (for validator operations)
VALOPER=$(republicd keys show validator --bech val -a --home $HOME/.republic)
echo "Validator Address: $VALOPER"

# Consensus address (for consensus)
CONSENSUS_ADDRESS=$(republicd comet show-address --home $HOME/.republic)
echo "Consensus Address: $CONSENSUS_ADDRESS"
```

### 3. Get the Consensus Pubkey

```bash
CONSENSUS_PUBKEY=$(republicd comet show-validator --home $HOME/.republic)
echo "Consensus Pubkey: $CONSENSUS_PUBKEY"
```

## 🛡️ Validator Creation

### 1. Get Test Tokens (Faucet)

Visit the RepublicAI Testnet faucet and enter your account address to get test tokens:
- [RepublicAI Faucet](https://points.republicai.io/faucet)

### 2. Create a Validator Configuration File

```bash
cat > $HOME/validator.json <<EOF
{
  "pubkey": $CONSENSUS_PUBKEY,
  "amount": "100000000000000000000arai",
  "moniker": "$MONIKER",
  "identity": "",
  "website": "",
  "details": "Republic AI Validator",
  "commission-rate": "0.10",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
EOF
```

> **Note**:
> - Ensure the node is synced (`catching_up: false`) before creating the validator
> - Important to adjust `amount`: in this command Initial delegation amount (100 RAI in arai units)
> - Adjust commissions according to your policy

### 3. Create the Validator

```bash
republicd tx staking create-validator $HOME/validator.json \
  --from validator \
  --chain-id raitestnet_77701-1 \
  --home $HOME/.republic \
  --gas-prices 250000000arai \
  --gas auto \
  --gas-adjustment 1.5 \
  -y
```

### 4. Verify the Validator

```bash
republicd query staking validator $VALOPER --home $HOME/.republic | grep -E "jailed|status|tokens"
```

**Expected output:**
```
  jailed: false
  status: BOND_STATUS_BONDED
  tokens: "100000000000000000000"
```

## 📋 Important Commands

### Status and Monitoring
```bash
# Check node status
republicd status 2>&1 | jq '.sync_info'

# Check the latest block height
republicd status 2>&1 | jq -r '.sync_info.latest_block_height'

# Check validator status
VALOPER=$(republicd keys show validator --bech val -a --home $HOME/.republic)
republicd query staking validator $VALOPER --home $HOME/.republic | grep -E "jailed|status|tokens"
```

### Validator Management

#### Unjail Validator
If your validator gets jailed, you can unjail it with the following command:
```bash
republicd tx slashing unjail \
  --from validator \
  --chain-id raitestnet_77701-1 \
  --home $HOME/.republic \
  --gas-prices 250000000arai \
  --gas auto \
  --gas-adjustment 1.5 \
  -y
```

#### Delegate to Validator
To delegate additional tokens (e.g., 50 RAI) to your validator:
```bash
republicd tx staking delegate \
  $VALOPER \
  50000000000000000000arai \
  --from validator \
  --chain-id raitestnet_77701-1 \
  --home $HOME/.republic \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 250000000arai \
  -y
```

#### Withdraw Rewards
To withdraw all pending rewards:
```bash
republicd tx distribution withdraw-all-rewards \
  --from validator \
  --chain-id raitestnet_77701-1 \
  --home $HOME/.republic \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 250000000arai \
  -y
```

#### Withdraw Rewards and Commission
To withdraw rewards and commission:
```bash
republicd tx distribution withdraw-rewards \
  $VALOPER \
  --from validator \
  --commission \
  --chain-id raitestnet_77701-1 \
  --home $HOME/.republic \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 250000000arai \
  -y
```

### Service Management
```bash
# Start the node
sudo systemctl start republicd

# Stop the node
sudo systemctl stop republicd

# Restart the node
sudo systemctl restart republicd

# Check the service status
sudo systemctl status republicd

# Monitor logs
sudo journalctl -u republicd -f -o cat
```

## 🔄 Updating to a New Version

### Update Procedure
```bash
# Stop the service
sudo systemctl stop republicd

# Download the new version
wget https://github.com/RepublicAI/republicd/releases/download/<version>/republicd -O republicd
chmod +x republicd
sudo mv republicd /usr/local/bin/

# Verify the version
republicd version

# Restart the service
sudo systemctl start republicd
```

> **Note**:
> - Change <version> to lasted version on [Release Notes](https://github.com/RepublicAI/networks/releases/)


## 📦 Backup and Recovery

### Back Up Important Files
```bash
# Create a backup directory
mkdir -p $HOME/republicd_backup

# Back up critical files
cp $HOME/.republic/config/priv_validator_key.json $HOME/republicd_backup/
cp $HOME/.republic/config/node_key.json $HOME/republicd_backup/
cp $HOME/.republic/config/genesis.json $HOME/republicd_backup/
cp $HOME/.republic/config/config.toml $HOME/republicd_backup/
cp $HOME/.republic/config/app.toml $HOME/republicd_backup/

# Compress the backup
cd $HOME/republicd_backup
tar -czvf republicd_backup_$(date +%Y%m%d).tar.gz *.json *.toml

# Save to a secure location (e.g., cloud storage)
```

### Recovering from a Backup
```bash
# Stop the service
sudo systemctl stop republicd

# Extract the backup
tar -xzvf republicd_backup_DATE.tar.gz -C $HOME/.republic/config/

# Restart the service
sudo systemctl start republicd
```

## 🛠️ Troubleshooting

### 1. Node Not Syncing (`catching_up: true`)

If the node does not sync after a long time:

```bash
# Stop the service
sudo systemctl stop republicd

# Reset state sync
SNAP_RPC="https://statesync.republicai.io"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000))
TRUST_HASH=$(curl -s \"$SNAP_RPC/block?height=$BLOCK_HEIGHT\" | jq -r .result.block_id.hash)
sed -i.bak -E "s|^(trust_height *=).*|\1 $BLOCK_HEIGHT|; \
s|^(trust_hash *=).*|\1 \"$TRUST_HASH\"|" \
$HOME/.republic/config/config.toml

# Restart the service
sudo systemctl start republicd
```

### 2. Validator Gets Jailed

If your validator gets jailed:

```bash
# Check the sync status
republicd status 2>&1 | jq '.sync_info.catching_up'

# If false, the node is synced, then unjail
republicd tx slashing unjail \
  --from validator \
  --chain-id raitestnet_77701-1 \
  --home $HOME/.republic \
  --gas-prices 250000000arai \
  --gas auto \
  --gas-adjustment 1.5 \
  -y
```

### 3. Peer Connection Issues

If the node does not connect to peers:

```bash
# Check the current peers
republicd status 2>&1 | jq '.node_info.network'

# Try alternative peers
PEERS="e281dc6e4ebf5e32fb7e6c4a111c06f02a1d4d62@3.92.139.74:26656,cfb2cb90a241f7e1c076a43954f0ee6d42794d04@54.173.6.183:26656"
sed -i.bak "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.republic/config/config.toml

# Restart the service
sudo systemctl restart republicd
```

# 🗑️ RepublicAI Validator Uninstall Guide

This guide provides comprehensive steps to safely and completely remove the RepublicAI Validator from your system. It covers stopping services, deleting binaries, removing configuration files, and cleaning up firewall rules.

## ⚠️ Warning: Backup Important Files

Before proceeding with the uninstallation process, it is **crucial** to back up all important files. Failure to do so may result in irreversible data loss, especially if you plan to reinstall the validator or need access to your existing validator keys and wallet information in the future. Please ensure you have secure copies of the following:

-   `priv_validator_key.json`: Your validator's private key.
-   `node_key.json`: Your node's private key.
-   Your wallet's **seed phrase**: This is essential for recovering your wallet and funds.

## 🔧 Uninstallation Steps

Follow these steps carefully to uninstall the RepublicAI Validator:

### 1. Stop and Disable Systemd Service

First, stop the running RepublicAI service and disable it to prevent it from starting automatically on boot. Then, remove the systemd service file and reload the systemd daemon.

```bash
# Stop the RepublicAI service
sudo systemctl stop republicd

# Disable the service to prevent it from running on boot
sudo systemctl disable republicd

# Remove the systemd service file
sudo rm /etc/systemd/system/republicd.service

# Reload systemd daemon to apply changes
sudo systemctl daemon-reload
```

### 2. Remove RepublicAI Binary

Delete the RepublicAI executable binary from your system.

```bash
# Remove the binary from the system
sudo rm /usr/local/bin/republicd
```

### 3. Remove Configuration Directory

Remove the entire RepublicAI configuration directory, which contains all validator-related data and settings.

```bash
# Remove the entire configuration directory
rm -rf $HOME/.republic
```

### 4. Remove Go (Optional)

If Go was installed solely for the purpose of running the RepublicAI Validator and is not required for other applications on your system, you can remove its installation and related environment variables.

```bash
# Remove Go installation directory
sudo rm -rf /usr/local/go

# Remove the Go archive file (if it exists)
rm -f $HOME/go${GO_VERSION}.linux-amd64.tar.gz

# Remove Go PATH entries from .bashrc
sed -i '/go\/bin/d' $HOME/.bashrc

# Apply the changes to the current shell session
source $HOME/.bashrc
```

### 5. Remove Firewall Rules

Delete any firewall rules that were specifically created for the RepublicAI Validator to allow incoming connections.

```bash
# Delete firewall rules for RepublicAI ports
sudo ufw delete allow 26656/tcp
sudo ufw delete allow 26657/tcp
sudo ufw delete allow 1317/tcp
```

## ✅ Verification of Uninstallation

To confirm that the RepublicAI Validator has been completely removed from your system, execute the following commands. The expected output indicates successful removal.

```bash
# Check if the binary still exists (should return no output or an error)
which republicd

# Check the status of the service (should return no output)
systemctl list-units | grep republicd

# Check for the configuration directory (should indicate it's not found)
ls -la $HOME/.republic 2>/dev/null || echo "Direktori .republic tidak ditemukan"
```

If all the above commands produce no output or explicitly state that the file/directory was not found, then the RepublicAI Validator has been successfully uninstalled from your system.

## 💡 Additional Notes

1.  **Backup for Reinstallation**: If you anticipate reinstalling the RepublicAI Validator in the future, it is highly recommended to keep a secure backup of the following files:
    ```bash
    # Create a backup directory
    mkdir -p $HOME/republicd_backup

    # Copy important configuration files to the backup directory
    cp $HOME/.republic/config/priv_validator_key.json $HOME/republicd_backup/
    cp $HOME/.republic/config/node_key.json $HOME/republicd_backup/
    ```

2.  **Go Installation**: The removal of Go (Step 4) is entirely optional. Only perform this step if Go was installed exclusively for RepublicAI and is not needed for any other applications on your server.

3.  **Blockchain Status**: This uninstallation process only removes the software from your local system. It **does not** remove your transaction history or your validator's status on the RepublicAI blockchain. Your validator will remain registered on the blockchain until you manually unbond or undelegate your stake through the appropriate blockchain commands or interface.


## ❓ FAQ

**Q: What's the difference between an account address, a validator address, and a consensus address?**  
A:
- Account address (prefix `rai...`): For regular transactions
- Validator address (prefix `raivaloper...`): For validator operations
- Consensus address (prefix `raivalcons...`): For consensus and slashing

**Q: How long does state sync take?**  
A: Typically 5-15 minutes, depending on your server specifications and situation.

**Q: How do I check the amount of rewards available for withdrawal?**  
A: Use the command:
```bash
republicd query distribution rewards $(republicd keys show validator -a --home $HOME/.republic) --home $HOME/.republic
```

**Q: What should I do if my validator gets jailed?**  
A: Ensure the node is synced (`catching_up: false`), then run the unjail command.

## 🔗 References

- [RepublicAI Networks Repository](https://github.com/RepublicAI/networks)
- [RepublicAI Testnet Documentation](https://github.com/RepublicAI/networks/blob/main/testnet/README.md)
- [RepublicAI v0.2.1 Release Notes](https://github.com/RepublicAI/networks/releases/tag/v0.2.1)
- [RepublicAI Discord](https://discord.gg/republicai)
- [RepublicAI Faucet](https://points.republicai.io/faucet)

---

## 🛡️ Support?


## [Apply My Code to join Point program before claim faucet](https://points.republicai.io/?ref=1B1344) and contact my if u need legal consult for free.


**Important Note**: This guide is based on RepublicAI version v0.2.1. Be sure to check the [release page](https://github.com/RepublicAI/networks/releases) for the latest information before installation.

> **Disclaimer**: Testnet tokens have no real economic value. This guide is for technical testing purposes only.



*© 2026 RepublicAI Validator Community. This guide is created for educational purposes.*

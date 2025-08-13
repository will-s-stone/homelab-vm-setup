#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGCLPQuG6u8XOUggPRUYNRu6hIO+2JkaT4/GKCgD85CX tailscale-machines"

echo -e "${GREEN}Setting up VM for persistent SSH sessions...${NC}"

if ! dpkg -l | grep -q openssh-server; then
    echo "Installing OpenSSH server..."
    sudo apt update
    sudo apt install -y openssh-server
fi

echo "Configuring SSH..."
if ! grep -q "ClientAliveInterval" /etc/ssh/sshd_config; then
    echo -e "\nClientAliveInterval 60\nClientAliveCountMax 10000\nTCPKeepAlive yes" | sudo tee -a /etc/ssh/sshd_config
fi
sudo systemctl restart ssh

echo "Disabling sleep modes..."
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

echo "Enabling session lingering..."
sudo loginctl enable-linger $USER

echo "Installing tmux..."
sudo apt install -y tmux

echo "Adding SSH key..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "Disabling automatic updates..."
sudo systemctl disable unattended-upgrades 2>/dev/null
sudo systemctl stop unattended-upgrades 2>/dev/null

echo -e "\n${GREEN}Setup complete!${NC}"
echo "Run 'sudo tailscale up' to connect to your tailnet"


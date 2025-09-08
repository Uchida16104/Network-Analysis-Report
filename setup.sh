#!/bin/bash

echo "Setting up network analysis tools for Ubuntu..."

sudo apt-get update

echo "Installing required system packages..."
sudo apt-get install -y \
    python3 \
    python3-venv \
    python3-pip \
    tcpdump \
    tshark \
    arp-scan \
    graphviz \
    net-tools \
    iproute2

echo "Setting up Python virtual environment..."
python3 -m venv myenv
source myenv/bin/activate
pip install --upgrade pip
pip install graphviz

echo "Setting execute permissions..."
chmod +x ve.sh
chmod +x capture.sh
chmod +x analyse.sh
chmod +x analyse.py

echo "Adding user to wireshark group..."
sudo usermod -a -G wireshark "$USER" 2>/dev/null || echo "wireshark group not found, skipping..."

echo ""
echo "Setup completed successfully!"
echo ""
echo "Usage:"
echo "  1. Run './capture.sh' to start network capture and analysis"
echo "  2. Or run './analyse.sh' to perform network discovery and analysis only"
echo ""
echo "Note: You may need to log out and log back in for group changes to take effect."
echo "      Some commands require sudo privileges for network access."

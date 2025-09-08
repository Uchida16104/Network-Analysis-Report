#!/bin/bash

INTERFACE=$(ip route | grep '^default' | head -1 | awk '{print $5}')

if [ -z "$INTERFACE" ]; then
    echo "Error: Could not detect network interface."
    exit 1
fi

echo "Using network interface: $INTERFACE for analysis"

command -v arp-scan >/dev/null 2>&1 || { echo >&2 "arp-scan is required but not installed. Run: sudo apt-get install arp-scan"; exit 1; }

echo "Performing ARP scan on interface $INTERFACE..."
sudo arp-scan -I "$INTERFACE" -l -v -D > hosts.txt 2>/dev/null || {
    echo "ARP scan failed. Trying alternative method..."
    NETWORK=$(ip route | grep "$INTERFACE" | grep '/' | head -1 | awk '{print $1}')
    if [ -n "$NETWORK" ]; then
        sudo arp-scan -I "$INTERFACE" "$NETWORK" > hosts.txt 2>/dev/null
    fi
}

source myenv/bin/activate || {
    echo "Virtual environment not found. Creating it now..."
    bash ve.sh
    source myenv/bin/activate
}

echo "Running Python analysis..."
python3 analyse.py "$INTERFACE"

echo "Analysis completed. Check network_map.png for results."

#!/bin/bash

INTERFACE=$(ip route | grep '^default' | head -1 | awk '{print $5}')

if [ -z "$INTERFACE" ]; then
    echo "Error: Could not detect network interface. Please specify manually."
    echo "Available interfaces:"
    ip link show | grep '^[0-9]' | awk -F': ' '{print $2}' | grep -v '^lo'
    exit 1
fi

echo "Using network interface: $INTERFACE"

command -v tcpdump >/dev/null 2>&1 || { echo >&2 "tcpdump is required but not installed. Run: sudo apt-get install tcpdump"; exit 1; }
command -v tshark >/dev/null 2>&1 || { echo >&2 "tshark is required but not installed. Run: sudo apt-get install tshark"; exit 1; }

echo "Starting packet capture on interface $INTERFACE..."
sudo tcpdump -i "$INTERFACE" -nn -w traffic.pcap &
TCPDUMP_PID=$!

sleep 2
echo "Starting network statistics..."
sudo tshark -i "$INTERFACE" -q -z conv,ip &
TSHARK_PID=$!

echo "Starting analysis..."
bash analyse.sh

echo "Stopping capture processes..."
sudo kill $TCPDUMP_PID 2>/dev/null
sudo kill $TSHARK_PID 2>/dev/null

echo "Network capture and analysis completed."

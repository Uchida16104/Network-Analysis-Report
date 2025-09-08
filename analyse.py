#!/usr/bin/env python3
import subprocess
import sys
import os
import signal
import time

try:
    import graphviz
except ImportError:
    print("graphviz module not found. Installing...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "graphviz"])
    import graphviz

def signal_handler(sig, frame):
    print('\nStopping analysis...')
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

interface = sys.argv[1] if len(sys.argv) > 1 else "eth0"

hosts = {}
if os.path.exists("hosts.txt"):
    with open("hosts.txt", "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) >= 2:
                ip = parts[0]
                mac = parts[1]
                if ip.count('.') == 3:
                    hosts[ip] = mac
else:
    print("Warning: hosts.txt not found. Creating empty network map.")

print(f"Found {len(hosts)} hosts from ARP scan")

print("Capturing network traffic for analysis...")
try:
    tshark_output = subprocess.check_output([
        "sudo", "tshark", "-i", interface, "-T", "fields", 
        "-e", "ip.src", "-e", "ip.dst", "-c", "50", "-q"
    ], text=True, timeout=30, stderr=subprocess.DEVNULL)
except subprocess.TimeoutExpired:
    print("Traffic capture timed out, using existing data")
    tshark_output = ""
except subprocess.CalledProcessError as e:
    print(f"tshark failed: {e}")
    tshark_output = ""

dot = graphviz.Digraph(comment="Network Map", format="png")
dot.attr(rankdir='TB', size='12,8')
dot.attr('node', shape='box', style='rounded,filled', fillcolor='lightblue')

for ip, mac in hosts.items():
    label = f"{ip}\\n{mac[:8]}..."
    dot.node(ip, label)

connections = set()
if tshark_output:
    for line in tshark_output.strip().splitlines():
        parts = line.split('\t')
        if len(parts) >= 2:
            src, dst = parts[0].strip(), parts[1].strip()
            if src and dst and src != dst:
                connection = tuple(sorted([src, dst]))
                if connection not in connections:
                    connections.add(connection)
                    dot.edge(src, dst, dir='both')

if not connections and hosts:
    print("No traffic captured, showing discovered hosts only")

print(f"Creating network map with {len(hosts)} hosts and {len(connections)} connections")

try:
    dot.render("network_map", cleanup=True)
    print("Network map generated successfully: network_map.png")
except Exception as e:
    print(f"Error generating graph: {e}")
    print("\nNetwork Information (Text Format):")
    print("=" * 40)
    for ip, mac in hosts.items():
        print(f"Host: {ip} - MAC: {mac}")
    
    if connections:
        print(f"\nConnections ({len(connections)}):")
        for src, dst in connections:
            print(f"  {src} <-> {dst}")

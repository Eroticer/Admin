#!/bin/bash

echo "=== Setting up NAT on inetRouter ==="

vagrant ssh inetRouter -c "
# Clean existing rules
sudo iptables -t nat -F
sudo iptables -F

# Configure NAT
sudo iptables -t nat -A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Save rules
sudo iptables-save | sudo tee /etc/sysconfig/iptables

echo '=== NAT Rules ==='
sudo iptables -t nat -L
sudo iptables -L

echo '=== inetRouter ready as gateway ==='
" 2>/dev/null

echo "✓ NAT configured on inetRouter"

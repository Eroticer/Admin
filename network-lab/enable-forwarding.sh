#!/bin/bash

echo "=== Enabling IP forwarding on routers ==="

enable_forwarding() {
    local machine=$1
    
    echo "Enabling IP forwarding on $machine..."
    vagrant ssh $machine -c "
sudo sysctl net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo systemctl stop firewalld
sudo systemctl disable firewalld
echo 'IP forwarding enabled on $machine'
cat /proc/sys/net/ipv4/ip_forward
" 2>/dev/null && echo "✓ $machine forwarding enabled" || echo "✗ Failed on $machine"
}

enable_forwarding inetRouter
enable_forwarding centralRouter  
enable_forwarding office1Router
enable_forwarding office2Router

echo "=== IP forwarding configured ==="

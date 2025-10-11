#!/bin/bash

echo "=== Network Lab Setup with Rocky Linux 9 ==="

wait_for_machine() {
    local machine=$1
    echo "Waiting for $machine to be ready..."
    until vagrant ssh $machine -c "echo 'OK'" &>/dev/null; do
        echo "  $machine not ready yet, waiting..."
        sleep 10
    done
    echo "✓ $machine is ready"
}

configure_rocky_machine() {
    local machine=$1
    local script=$2
    
    echo "Configuring $machine..."
    if vagrant ssh $machine -c "$script" 2>/dev/null; then
        echo "✓ $machine configured successfully"
    else
        echo "✗ Failed to configure $machine"
        return 1
    fi
}

# Ждем готовности машин
for machine in inetRouter centralRouter centralServer office1Router office1Server office2Router office2Server; do
    wait_for_machine $machine
done

echo "1. Configuring inetRouter (NAT Gateway)..."
configure_rocky_machine inetRouter "
# Enable IP forwarding
sudo sysctl net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf

# Disable firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Configure NAT
sudo iptables -t nat -A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Save iptables rules
sudo iptables-save | sudo tee /etc/sysconfig/iptables

echo '=== inetRouter Status ==='
ip addr show | grep 'inet ' | grep -v '127.0.0.1'
echo '--- Routes ---'
ip route
"

echo "2. Configuring centralRouter..."
configure_rocky_machine centralRouter "
# Enable IP forwarding
sudo sysctl net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf

# Disable firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Add routes
sudo ip route add 0.0.0.0/0 via 192.168.255.1
sudo ip route add 192.168.2.0/24 via 192.168.255.10
sudo ip route add 192.168.1.0/24 via 192.168.255.6

echo '=== centralRouter Status ==='
ip addr show | grep 'inet ' | grep -v '127.0.0.1'
echo '--- Routes ---'
ip route
"

echo "3. Configuring office1Router..."
configure_rocky_machine office1Router "
# Enable IP forwarding
sudo sysctl net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf

# Disable firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Add routes
sudo ip route add 0.0.0.0/0 via 192.168.255.9
sudo ip route add 192.168.0.0/24 via 192.168.255.9
sudo ip route add 192.168.1.0/24 via 192.168.255.9

echo '=== office1Router Status ==='
ip addr show | grep 'inet ' | grep -v '127.0.0.1'
echo '--- Routes ---'
ip route
"

echo "4. Configuring office2Router..."
configure_rocky_machine office2Router "
# Enable IP forwarding
sudo sysctl net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf

# Disable firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Add routes
sudo ip route add 0.0.0.0/0 via 192.168.255.5
sudo ip route add 192.168.0.0/24 via 192.168.255.5
sudo ip route add 192.168.2.0/24 via 192.168.255.5

echo '=== office2Router Status ==='
ip addr show | grep 'inet ' | grep -v '127.0.0.1'
echo '--- Routes ---'
ip route
"

echo "5. Configuring servers with default routes..."
configure_rocky_machine centralServer "sudo ip route add 0.0.0.0/0 via 192.168.0.1"
configure_rocky_machine office1Server "sudo ip route add 0.0.0.0/0 via 192.168.2.129"  
configure_rocky_machine office2Server "sudo ip route add 0.0.0.0/0 via 192.168.1.1"

echo "6. Installing network tools..."
for machine in inetRouter centralRouter office1Router office2Router centralServer office1Server office2Server; do
    configure_rocky_machine $machine "sudo dnf install -y traceroute tcpdump net-tools" || echo "Skipping tools installation on $machine"
done

echo "=== Network Lab Setup Complete ==="

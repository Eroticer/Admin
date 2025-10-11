#!/bin/bash

echo "=== Fixing routing tables ==="

fix_routes() {
    local machine=$1
    local cmd=$2
    
    echo "Fixing routes on $machine..."
    vagrant ssh $machine -c "$cmd" 2>/dev/null && echo "✓ $machine routes fixed" || echo "✗ Failed to fix $machine routes"
}

echo "1. Removing default routes via eth0 and adding correct routes..."

# inetRouter - оставляем как есть (он шлюз)
fix_routes inetRouter "
echo 'inetRouter routes are correct'
"

# centralRouter - добавляем маршруты
fix_routes centralRouter "
sudo ip route del default via 192.168.121.1
sudo ip route add default via 192.168.255.1
sudo ip route add 192.168.2.0/24 via 192.168.255.10
sudo ip route add 192.168.1.0/24 via 192.168.255.6
echo '=== centralRouter New Routes ==='
ip route
"

# office1Router - добавляем маршруты  
fix_routes office1Router "
sudo ip route del default via 192.168.121.1
sudo ip route add default via 192.168.255.9
sudo ip route add 192.168.0.0/24 via 192.168.255.9
sudo ip route add 192.168.1.0/24 via 192.168.255.9
echo '=== office1Router New Routes ==='
ip route
"

# office2Router - добавляем маршруты
fix_routes office2Router "
sudo ip route del default via 192.168.121.1
sudo ip route add default via 192.168.255.5
sudo ip route add 192.168.0.0/24 via 192.168.255.5
sudo ip route add 192.168.2.0/24 via 192.168.255.5
echo '=== office2Router New Routes ==='
ip route
"

# Серверы - меняем маршрут по умолчанию
fix_routes centralServer "
sudo ip route del default via 192.168.121.1
sudo ip route add default via 192.168.0.1
echo '=== centralServer New Routes ==='
ip route
"

fix_routes office1Server "
sudo ip route del default via 192.168.121.1  
sudo ip route add default via 192.168.2.129
echo '=== office1Server New Routes ==='
ip route
"

fix_routes office2Server "
sudo ip route del default via 192.168.121.1
sudo ip route add default via 192.168.1.1
echo '=== office2Server New Routes ==='
ip route
"

echo "2. Testing new routing..."
echo "Testing office1Server internet via new route:"
vagrant ssh office1Server -c "traceroute -n -m 3 8.8.8.8" 2>/dev/null

echo "=== Routes fixed ==="

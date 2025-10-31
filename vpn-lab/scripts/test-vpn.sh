#!/bin/bash

echo "=== Testing TUN/TAP VPN ==="

# 1. Проверяем интерфейсы
echo "1. Checking interfaces..."
echo "Server:"
vagrant ssh tun-tap-server -c 'ip addr show | grep -E "(tap|tun)" || echo "No TAP/TUN interface"'
echo "Client:"
vagrant ssh tun-tap-client -c 'ip addr show | grep -E "(tap|tun)" || echo "No TAP/TUN interface"'

# 2. Проверяем IP адреса
echo "2. Checking IP addresses..."
echo "Server:"
vagrant ssh tun-tap-server -c 'ip addr show | grep "10.10.10.1" || echo "No 10.10.10.1 address"'
echo "Client:"
vagrant ssh tun-tap-client -c 'ip addr show | grep "10.10.10.2" || echo "No 10.10.10.2 address"'

# 3. Тестируем соединение
echo "3. Testing connectivity..."
vagrant ssh tun-tap-client -c 'ping -c 3 10.10.10.1'

# 4. Тестируем производительность
echo "4. Testing performance..."
vagrant ssh tun-tap-server -c 'sudo pkill iperf3; iperf3 -s -D'
sleep 2
vagrant ssh tun-tap-client -c 'iperf3 -c 10.10.10.1 -t 10 -i 2'

echo "=== Test complete ==="

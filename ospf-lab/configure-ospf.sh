#!/bin/bash
echo "=== Configuring OSPF ==="

# Включаем IP forwarding и отключаем firewalld
for i in 1 2 3; do
  echo "Configuring router$i..."
  vagrant ssh router$i -c "sudo echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf"
  vagrant ssh router$i -c "sudo echo 'net.ipv4.conf.all.rp_filter = 0' >> /etc/sysctl.conf"
  vagrant ssh router$i -c "sudo sysctl -p"
  vagrant ssh router$i -c "sudo systemctl stop firewalld && sudo systemctl disable firewalld"
done

# Настройка FRR OSPF
echo "Setting up FRR OSPF..."

# Router1
vagrant ssh router1 -c "sudo vtysh -c 'conf t' -c 'router ospf' -c 'router-id 1.1.1.1' -c 'network 10.0.10.0/30 area 0' -c 'network 10.0.12.0/30 area 0' -c 'interface eth1' -c 'ip ospf cost 1000' -c 'exit' -c 'exit' -c 'write'"

# Router2
vagrant ssh router2 -c "sudo vtysh -c 'conf t' -c 'router ospf' -c 'router-id 2.2.2.2' -c 'network 10.0.10.0/30 area 0' -c 'network 10.0.11.0/30 area 0' -c 'exit' -c 'write'"

# Router3
vagrant ssh router3 -c "sudo vtysh -c 'conf t' -c 'router ospf' -c 'router-id 3.3.3.3' -c 'network 10.0.11.0/30 area 0' -c 'network 10.0.12.0/30 area 0' -c 'exit' -c 'write'"

echo "=== OSPF configuration complete ==="

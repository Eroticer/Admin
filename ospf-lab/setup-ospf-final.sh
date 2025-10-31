#!/bin/bash
echo "=== Configuring OSPF ==="

# Router1
echo "Configuring router1..."
vagrant ssh router1 -c "sudo vtysh -c 'conf t' -c 'router ospf' -c 'router-id 1.1.1.1' -c 'network 10.0.10.0/30 area 0' -c 'network 10.0.12.0/30 area 0' -c 'exit' -c 'interface eth1' -c 'ip ospf cost 1000' -c 'exit' -c 'write'"

# Router2
echo "Configuring router2..."
vagrant ssh router2 -c "sudo vtysh -c 'conf t' -c 'router ospf' -c 'router-id 2.2.2.2' -c 'network 10.0.10.0/30 area 0' -c 'network 10.0.11.0/30 area 0' -c 'exit' -c 'write'"

# Router3
echo "Configuring router3..."
vagrant ssh router3 -c "sudo vtysh -c 'conf t' -c 'router ospf' -c 'router-id 3.3.3.3' -c 'network 10.0.11.0/30 area 0' -c 'network 10.0.12.0/30 area 0' -c 'exit' -c 'write'"

echo "=== OSPF configuration complete ==="

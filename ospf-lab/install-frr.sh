#!/bin/bash
echo "=== Installing and configuring FRR ==="

for i in 1 2 3; do
  echo "Setting up router$i..."
  
  # Устанавливаем FRR
  vagrant ssh router$i -c "sudo dnf install -y epel-release"
  vagrant ssh router$i -c "sudo dnf install -y frr"
  
  # Настраиваем демоны
  vagrant ssh router$i -c "sudo sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons"
  vagrant ssh router$i -c "sudo sed -i 's/zebra=no/zebra=yes/' /etc/frr/daemons"
  
  # Включаем IP forwarding
  vagrant ssh router$i -c "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf"
  vagrant ssh router$i -c "echo 'net.ipv4.conf.all.rp_filter = 0' | sudo tee -a /etc/sysctl.conf"
  vagrant ssh router$i -c "sudo sysctl -p"
  
  # Отключаем firewalld
  vagrant ssh router$i -c "sudo systemctl stop firewalld && sudo systemctl disable firewalld"
  
  # Запускаем FRR
  vagrant ssh router$i -c "sudo systemctl enable frr && sudo systemctl start frr"
done

echo "=== FRR installation complete ==="

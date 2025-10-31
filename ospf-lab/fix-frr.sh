#!/bin/bash
echo "=== Fixing FRR configuration ==="

for i in 1 2 3; do
  echo "Fixing router$i..."
  
  # Проверяем текущую конфигурацию демонов
  vagrant ssh router$i -c "sudo cat /etc/frr/daemons | grep ospfd"
  
  # Исправляем конфигурацию демонов
  vagrant ssh router$i -c "sudo sed -i 's/^ospfd=no/ospfd=yes/g' /etc/frr/daemons"
  vagrant ssh router$i -c "sudo sed -i 's/^zebra=no/zebra=yes/g' /etc/frr/daemons"
  vagrant ssh router$i -c "sudo sed -i 's/^ospfd=yes/ospfd=yes/g' /etc/frr/daemons"  # На всякий случай
  
  # Проверяем что изменилось
  vagrant ssh router$i -c "sudo cat /etc/frr/daemons | grep ospfd"
  
  # Перезапускаем FRR
  vagrant ssh router$i -c "sudo systemctl restart frr"
  
  # Ждем немного
  sleep 2
done

echo "=== FRR configuration fixed ==="

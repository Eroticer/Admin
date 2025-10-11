#!/bin/bash

echo "Creating libvirt networks..."

# Удаляем старые сети если они есть
echo "Cleaning up old networks..."
for network in dev1-net dev2-net dir-net hw-net management managers-net mgt-net office1-central office1-net office2-central office2-net router-net test1-net test2-net; do
    sudo virsh net-destroy "$network" 2>/dev/null || true
    sudo virsh net-undefine "$network" 2>/dev/null || true
done

# Ждем немного
sleep 2

# Создаем сети из XML файлов
for network_file in networks/*.xml; do
    network_name=$(basename "$network_file" .xml)
    
    echo "Creating network: $network_name"
    
    # Создаем новую сеть
    sudo virsh net-define "$network_file"
    sudo virsh net-start "$network_name"
    sudo virsh net-autostart "$network_name"
    
    echo "Network $network_name created successfully"
    echo "---"
done

echo "All networks created:"
sudo virsh net-list --all

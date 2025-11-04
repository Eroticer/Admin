#!/bin/bash

# Knocking script for SSH access to inetRouter
# Usage: ./knock-ssh <target_ip>

TARGET="${1:-192.168.10.1}"
PORTS="1111 2222 3333"

echo "Knocking on ports: $PORTS"
for port in $PORTS; do
    echo "Knocking on port $port"
    nmap -Pn --host-timeout 201 --max-retries 0 -p $port $TARGET > /dev/null 2>&1
    sleep 1
done

echo "Knocking sequence completed. Waiting for SSH port to open..."
sleep 2

# Try to connect via SSH
echo "Attempting SSH connection..."
ssh -o ConnectTimeout=5 vagrant@$TARGET
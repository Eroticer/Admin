#!/bin/bash

echo "=== Setting up TUN/TAP VPN ==="

# 1. Создаем service файлы
echo "1. Creating OpenVPN service files..."
for vm in tun-tap-server tun-tap-client; do
    vagrant ssh $vm -c 'sudo tee /etc/systemd/system/openvpn@.service > /dev/null << EOF
[Unit]
Description=OpenVPN Tunneling Application On %I
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF'
done

# 2. Перезагружаем systemd
echo "2. Reloading systemd..."
vagrant ssh tun-tap-server -c 'sudo systemctl daemon-reload'
vagrant ssh tun-tap-client -c 'sudo systemctl daemon-reload'

# 3. Создаем OpenVPN директории
echo "3. Creating OpenVPN directories..."
vagrant ssh tun-tap-server -c 'sudo mkdir -p /etc/openvpn'
vagrant ssh tun-tap-client -c 'sudo mkdir -p /etc/openvpn'

# 4. Генерируем статический ключ на сервере
echo "4. Generating static key on server..."
vagrant ssh tun-tap-server -c 'sudo openvpn --genkey secret /etc/openvpn/static.key'

# 5. Копируем конфигурации
echo "5. Copying configurations..."
vagrant ssh tun-tap-server -c 'sudo cp /vagrant/provisioning/tun-tap/server-tap.conf /etc/openvpn/server.conf'
vagrant ssh tun-tap-client -c 'sudo cp /vagrant/provisioning/tun-tap/client-tap.conf /etc/openvpn/server.conf'

# 6. Копируем ключ на клиент
echo "6. Copying static key to client..."
vagrant ssh tun-tap-server -c 'sudo cat /etc/openvpn/static.key' | vagrant ssh tun-tap-client -c 'sudo tee /etc/openvpn/static.key'

# 7. Исправляем права на ключ
echo "7. Fixing permissions..."
vagrant ssh tun-tap-client -c 'sudo chmod 600 /etc/openvpn/static.key'

# 8. Запускаем сервер
echo "8. Starting server..."
vagrant ssh tun-tap-server -c 'sudo systemctl start openvpn@server'
sleep 3

# 9. Запускаем клиент
echo "9. Starting client..."
vagrant ssh tun-tap-client -c 'sudo systemctl start openvpn@server'
sleep 3

# 10. Проверяем
echo "10. Verifying setup..."
echo "Server status:"
vagrant ssh tun-tap-server -c 'sudo systemctl is-active openvpn@server && echo "✓ Active" || echo "✗ Failed"'
echo "Client status:"
vagrant ssh tun-tap-client -c 'sudo systemctl is-active openvpn@server && echo "✓ Active" || echo "✗ Failed"'

echo "=== TUN/TAP setup complete ==="

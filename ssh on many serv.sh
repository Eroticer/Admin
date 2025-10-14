#!/bin/bash

declare -A marks=([tony_172.16.238.10]='Ir0nM@n' [steve_172.16.238.11]='Am3ric@' [banner_172.16.238.12]='BigGr33n' [loki_172.16.238.14]='Mischi3f' [peter_172.16.239.10]='Sp!dy' [natasha_172.16.238.15]='Bl@kW' [clint_172.16.238.16]='H@wk3y3' [groot_172.16.238.17]='Gr00T123' [jenkins_172.16.238.19]='j@rv!s')

sudo dnf install -y sshpass

for key in "${!marks[@]}"; do
    name=$(echo "$key" | cut -d'_' -f1)
    ip=$(echo "$key" | cut -d'_' -f2)
    password="${marks[$key]}"
    
    echo "=== Обрабатываем $name@$ip ==="
    
    # Выполняем команды на удаленном сервере через SSH
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$name@$ip" "
        # Создаем резервную копию конфига
        echo '$password' | sudo -S cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
        
        # Отключаем root-логин
        echo '$password' | sudo -S sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        echo '$password' | sudo -S sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        echo '$password' | sudo -S sed -i 's/^#PermitRootLogin without-password/PermitRootLogin no/' /etc/ssh/sshd_config
        echo '$password' | sudo -S sed -i 's/^PermitRootLogin without-password/PermitRootLogin no/' /etc/ssh/sshd_config
        
        # Перезапускаем SSH службу
        echo '$password' | sudo -S systemctl restart sshd
        echo 'SSH конфигурация изменена и служба перезапущена'
        
        # Проверяем текущую настройку
        echo 'Текущая настройка PermitRootLogin:'
        echo '$password' | sudo -S grep -i 'PermitRootLogin' /etc/ssh/sshd_config
    "
    
    if [ $? -eq 0 ]; then
        echo "✅ Успешно выполнено для $ip"
    else
        echo "❌ Ошибка при обработке $ip"
    fi
    echo ""
done
#!/bin/bash
# Расширенная настройка безопасности Docker для пользователей

set -e

DOCKER_USER="$1"
SUDOERS_FILE="/etc/sudoers.d/docker_$DOCKER_USER"

# Функция для проверки привилегий
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        echo "Этот скрипт должен выполняться с правами root" 
        exit 1
    fi
}

# Функция настройки ограниченных прав Docker
setup_restricted_docker_access() {
    local user="$1"
    
    # Создание ограниченного sudoers файла
    cat > "$SUDOERS_FILE" << EOF
# Ограниченные права Docker для пользователя $user
# Разрешены только безопасные команды

$user ALL=(root) NOPASSWD: /bin/systemctl restart docker
$user ALL=(root) NOPASSWD: /bin/systemctl status docker
$user ALL=(root) NOPASSWD: /usr/bin/docker ps
$user ALL=(root) NOPASSWD: /usr/bin/docker images
$user ALL=(root) NOPASSWD: /usr/bin/docker logs *

# Запрещенные команды (явный запрет)
$user ALL=(root) NOPASSWD: !/usr/bin/docker exec *
$user ALL=(root) NOPASSWD: !/usr/bin/docker run *
$user ALL=(root) NOPASSWD: !/usr/bin/docker rm *
$user ALL=(root) NOPASSWD: !/usr/bin/docker rmi *
EOF

    # Установка правильных прав
    chmod 440 "$SUDOERS_FILE"
    chown root:root "$SUDOERS_FILE"
    
    echo "Настроены ограниченные права Docker для пользователя $user"
}

# Функция создания alias для безопасного использования Docker
setup_docker_aliases() {
    local user="$1"
    local user_home=$(getent passwd "$user" | cut -d: -f6)
    
    # Создание файла с алиасами
    cat > "$user_home/.docker_aliases" << 'EOF'
# Безопасные алиасы Docker
alias dps='sudo docker ps'
alias dimages='sudo docker images'
alias dlogs='sudo docker logs'
alias drestart='sudo systemctl restart docker'
alias dstatus='sudo systemctl status docker'

# Запрещенные команды (сообщение об ошибке)
alias drun='echo "ERROR: Эта команда запрещена политикой безопасности"'
alias dexec='echo "ERROR: Эта команда запрещена политикой безопасности"'
alias drm='echo "ERROR: Эта команда запрещена политикой безопасности"'
EOF

    # Добавление в .bashrc
    echo "source ~/.docker_aliases" >> "$user_home/.bashrc"
    chown "$user:$user" "$user_home/.docker_aliases"
    chown "$user:$user" "$user_home/.bashrc"
    
    echo "Настроены алиасы Docker для пользователя $user"
}

# Функция настройки политики SELinux
setup_selinux_policies() {
    if command -v sestatus &> /dev/null; then
        if sestatus | grep -q "enabled"; then
            echo "Настройка политик SELinux для Docker..."
            setsebool -P docker_execstream on
            setsebool -P docker_connect_any on
            echo "Политики SELinux настроены"
        fi
    fi
}

# Основная функция
main() {
    check_privileges
    
    if [ -z "$DOCKER_USER" ]; then
        echo "Использование: $0 <username>"
        exit 1
    fi
    
    if ! id "$DOCKER_USER" &> /dev/null; then
        echo "Ошибка: Пользователь $DOCKER_USER не существует"
        exit 1
    fi
    
    echo "Начало настройки безопасного доступа к Docker для пользователя: $DOCKER_USER"
    
    setup_restricted_docker_access "$DOCKER_USER"
    setup_docker_aliases "$DOCKER_USER"
    setup_selinux_policies
    
    # Добавление пользователя в группу docker
    usermod -aG docker "$DOCKER_USER"
    
    echo "Настройка завершена!"
    echo "Пользователь $DOCKER_USER теперь имеет ограниченный доступ к Docker"
    echo "Файл настроек: $SUDOERS_FILE"
}

main "$@"

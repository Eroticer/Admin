#!/bin/bash
# Скрипт управления доступом к Docker для непривилегированных пользователей
# Проверяет права и настраивает окружение для работы с Docker

LOG_FILE="/var/log/docker_access.log"
DOCKER_USER="$1"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_docker_access() {
    # Проверка наличия Docker
    if ! command -v docker &> /dev/null; then
        log_message "ERROR: Docker не установлен"
        return 1
    fi
    
    # Проверка прав пользователя
    if groups "$DOCKER_USER" | grep -q '\bdocker\b'; then
        log_message "SUCCESS: Пользователь $DOCKER_USER имеет доступ к Docker"
        return 0
    else
        log_message "WARNING: Пользователь $DOCKER_USER не в группе docker"
        return 1
    fi
}

setup_docker_environment() {
    # Настройка переменных окружения для Docker
    local user_home=$(getent passwd "$DOCKER_USER" | cut -d: -f6)
    
    # Создание директории для Docker конфигов
    mkdir -p "$user_home/.docker"
    chown "$DOCKER_USER:$DOCKER_USER" "$user_home/.docker"
    chmod 700 "$user_home/.docker"
    
    # Настройка Docker socket прав (альтернативный метод)
    if [ -S "/var/run/docker.sock" ]; then
        docker_group=$(stat -c '%G' /var/run/docker.sock)
        if [ "$docker_group" != "docker" ]; then
            log_message "INFO: Docker socket принадлежит группе $docker_group"
        fi
    fi
    
    log_message "INFO: Окружение Docker настроено для пользователя $DOCKER_USER"
}

validate_docker_permissions() {
    # Проверка конкретных прав через sudo
    sudo -l -U "$DOCKER_USER" | grep -q "systemctl restart docker"
    if [ $? -eq 0 ]; then
        log_message "SUCCESS: Пользователь $DOCKER_USER может перезапускать Docker"
        return 0
    else
        log_message "WARNING: Пользователь $DOCKER_USER не имеет прав на перезапуск Docker"
        return 1
    fi
}

test_docker_commands() {
    # Тестирование Docker команд от имени пользователя
    local test_commands=(
        "docker version"
        "docker ps"
        "sudo systemctl status docker"
        "sudo systemctl restart docker"
    )
    
    for cmd in "${test_commands[@]}"; do
        sudo -u "$DOCKER_USER" bash -c "$cmd" &> /dev/null
        if [ $? -eq 0 ]; then
            log_message "SUCCESS: Команда выполнена: $cmd"
        else
            log_message "WARNING: Команда не выполнена: $cmd"
        fi
    done
}

main() {
    if [ -z "$DOCKER_USER" ]; then
        echo "Использование: $0 <username>"
        exit 1
    fi
    
    # Проверка существования пользователя
    if ! id "$DOCKER_USER" &> /dev/null; then
        echo "Ошибка: Пользователь $DOCKER_USER не существует"
        exit 1
    fi
    
    log_message "=== Начало проверки доступа к Docker для пользователя $DOCKER_USER ==="
    
    echo "Проверка доступа к Docker для пользователя: $DOCKER_USER"
    echo "Логирование в файл: $LOG_FILE"
    echo ""
    
    # Выполнение проверок
    check_docker_access
    setup_docker_environment
    validate_docker_permissions
    test_docker_commands
    
    log_message "=== Завершение проверки ==="
    
    # Вывод итогового отчета
    echo "Итоговый отчет:"
    tail -n 10 "$LOG_FILE" | grep -E "(SUCCESS|WARNING|ERROR)"
    
    echo ""
    echo "Полный лог доступен в: $LOG_FILE"
}

# Запуск основной функции
main "$@"

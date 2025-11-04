# Сценарии iptables с Knocking Port и Port Forwarding

## Архитектура решения

[ Host ] --> [ inetRouter2:8080 ] --> [ centralServer:80 ]
| |
| +--> [ centralRouter ] --> [ centralServer ]
|
+--> [ inetRouter ] --> [ centralRouter ] --> [ centralServer ]
text


## Компоненты системы

- **inetRouter** (192.168.10.1): Основной шлюз в интернет с knocking port для SSH
- **inetRouter2** (192.168.100.10): Дополнительный роутер с пробросом порта 8080→80
- **centralRouter** (192.168.10.3): Внутренний маршрутизатор
- **centralServer** (192.168.20.10): Веб-сервер с nginx

## Функциональность

### 1. Knocking Port на inetRouter

- По умолчанию SSH порт (22) закрыт
- Для доступа необходимо выполнить knocking последовательность: 1111, 2222, 3333 TCP
- После успешного knocking SSH порт открывается на 30 секунд

**Использование:**
```bash
# С centralRouter
/usr/local/bin/knock-ssh 192.168.10.1

# Или вручную
nmap -p 1111 192.168.10.1
nmap -p 2222 192.168.10.1  
nmap -p 3333 192.168.10.1
ssh vagrant@192.168.10.1

Запуск
bash

# Клонируйте репозиторий
git clone <repository>
cd iptables-scenario

# Запустите виртуальные машины
vagrant up --provider=libvirt

# Или запустите с Ansible provision
vagrant up --provider=libvirt --provision

Проверка работоспособности
1. Проверка knocking port
bash

# Подключитесь к centralRouter
vagrant ssh centralRouter

# Выполните knocking и подключитесь к inetRouter
/usr/local/bin/knock-ssh

2. Проверка port forwarding
bash

# С хоста откройте браузер или используйте curl
curl http://192.168.100.10:8080

3. Проверка маршрутизации
bash

# На centralRouter проверьте маршрут по умолчанию
ip route show

# Проверьте доступ в интернет
ping -c 3 8.8.8.8
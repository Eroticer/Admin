# Настройка VLAN и LACP

## Цель задания
Научиться настраивать VLAN и LACP для разделения сети и повышения отказоустойчивости.

## Задание
1. В Office1 в тестовой подсети настроить серверы с дополнительными интерфейсами
2. Развести VLAN:
   - testClient1 <-> testServer1 (VLAN 1)
   - testClient2 <-> testServer2 (VLAN 2)
3. Между centralRouter и inetRouter объединить 2 линка в бонд (LACP)

## Схема сети

inetRouter (192.168.255.1) <--bond--> centralRouter (192.168.255.2)
|
|
office1Router (192.168.255.10)
|
-----------------------------------
| |
VLAN 1 (10.10.10.0/24) VLAN 2 (10.10.10.0/24)
| |
testClient1 (10.10.10.254) testClient2 (10.10.10.254)
testServer1 (10.10.10.1) testServer2 (10.10.10.1)
text


## Команды для запуска

```bash
# Запуск виртуальных машин
vagrant up

# Настройка с помощью Ansible
ansible-playbook -i ansible/hosts ansible/provision.yml

# Проверка VLAN
vagrant ssh testClient1
ping 10.10.10.1

vagrant ssh testClient2  
ping 10.10.10.1

# Проверка LACP
vagrant ssh inetRouter
ping 192.168.255.2



## Инструкция по запуску

1. Убедитесь, что установлены:
   - Vagrant
   - libvirt
   - Ansible

2. Клонируйте репозиторий и перейдите в директорию проекта

3. Запустите виртуальные машины:
```bash
vagrant up

ansible-playbook -i ansible/hosts ansible/provision.yml

# Проверка VLAN 1
vagrant ssh testClient1
ping 10.10.10.1

# Проверка VLAN 2  
vagrant ssh testClient2
ping 10.10.10.1

# Проверка LACP
vagrant ssh inetRouter
ping 192.168.255.2

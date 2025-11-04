# Настройка FreeIPA сервера и клиентов

## Цель задания
Научиться настраивать LDAP-сервер FreeIPA и подключать к нему LDAP-клиентов.

## Задание
1) Установить FreeIPA сервер
2) Написать Ansible-playbook для конфигурации клиента
3) * Настроить аутентификацию по SSH-ключам
4) ** Firewall должен быть включен на сервере и на клиенте

## Схема сети

FreeIPA Server (ipa.otus.lan) - 192.168.57.10
|
|
----------------
| |
Client1 Client2
(192.168.57.11) (192.168.57.12)
text


## Команды для запуска

```bash
# Запуск виртуальных машин
vagrant up

# Настройка FreeIPA сервера и клиентов
ansible-playbook -i ansible/hosts ansible/provision.yml

# Проверка работы FreeIPA
vagrant ssh ipa.otus.lan
sudo -i
kinit admin
ipa user-find

# Проверка клиента
vagrant ssh client1.otus.lan
sudo -i
kinit otus-user
klist




# Получить билет Kerberos
kinit admin

# Просмотреть список пользователей
ipa user-find

# Проверить статус служб
ipactl status


# Аутентификация пользователя
kinit otus-user

# Проверить билет
klist







## Инструкция по запуску

1. Убедитесь, что установлены:
   - Vagrant
   - libvirt
   - Ansible

2. Клонируйте репозиторий и перейдите в директорию проекта

3. Запустите виртуальные машины:
```bash
vagrant up

    Настройте FreeIPA с помощью Ansible:

bash

cd ansible
ansible-playbook -i hosts provision.yml

    Проверьте работу:

bash

# Проверка сервера
vagrant ssh ipa.otus.lan
sudo -i
kinit admin
ipa user-find

# Проверка клиента
vagrant ssh client1.otus.lan
sudo -i
kinit otus-user
klist

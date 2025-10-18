# PXE Сервер для автоматической установки Ubuntu

## Обзор
Полная настройка PXE сервера для автоматической установки Ubuntu 22.04 LTS по сети.

## Архитектура
- **PXE Сервер**: 10.0.0.20 (dnsmasq + Apache2)
- **PXE Клиент**: DHCP из диапазона 10.0.0.100-120
- **Сервисы**: DHCP, TFTP, HTTP

## Быстрый старт
```bash
# Запуск окружения
vagrant up pxeserver

# Настройка PXE сервера
vagrant ssh pxeserver
sudo /vagrant/scripts/download-iso.sh

# Запуск PXE клиента (загрузится по сети)
vagrant up pxeclient

Сеть

    PXE Сеть: 10.0.0.0/24

    DHCP Диапазон: 10.0.0.100-120

    Шлюз: 10.0.0.20

    DNS: 8.8.8.8

Сервисы

    dnsmasq: DHCP + TFTP на eth1

    Apache2: HTTP сервер на порту 80

    TFTP Корень: /srv/tftp/amd64
Автоматическая установка

    Имя пользователя: otus

    Пароль: 123

    Имя хоста: ubuntu-pxe

    Автоматическое разделение диска

    SSH сервер включен

Структура файлов

    /srv/tftp/amd64/ - TFTP файлы (pxelinux.0, linux, initrd)

    /srv/images/ - ISO образы

    /srv/ks/ - Конфигурации автоматической установки

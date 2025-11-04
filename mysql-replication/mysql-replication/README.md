# GTID репликация MySQL для базы bet

Данный проект настраивает GTID репликацию между двумя узлами MySQL (Percona Server) с репликацией только указанных таблиц из базы bet.

## Архитектура

- **Master**: 192.168.56.150
- **Slave**: 192.168.56.151

## Реплицируемые таблицы

- bookmaker
- competition  
- market
- odds
- outcome

## Игнорируемые таблицы

- events_on_demand
- v_same_event

## Предварительные требования

- Vagrant
- Libvirt с KVM
- Доступ к интернету для загрузки образов

## Развертывание

1. Клонируйте репозиторий
2. Поместите файл `bet.dmp` в корневую директорию проекта
3. Запустите развертывание:


chmod +x scripts/*.sh
chmod +x check_replication.sh

```bash
vagrant up --provider=libvirt




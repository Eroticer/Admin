# Настройка PostgreSQL репликации и резервного копирования

## Цель задания
Настроить hot_standby репликацию PostgreSQL с использованием слотов и организовать правильное резервное копирование с помощью Barman.

## Архитектура решения

- **node1** (192.168.57.11) - Master PostgreSQL сервер
- **node2** (192.168.57.12) - Slave PostgreSQL сервер (hot standby)
- **barman** (192.168.57.13) - Сервер резервного копирования

## Технологии

- PostgreSQL 14
- Streaming Replication с использованием слотов
- Barman для резервного копирования
- Ansible для автоматизации развертывания
- Libvirt/KVM для виртуализации

## Развертывание

### Предварительные требования

- Vagrant
- Libvirt с KVM
- Ansible

### Запуск стенда

```bash
# Клонируйте репозиторий
git clone <repository-url>
cd postgres-replication

# Запустите виртуальные машины
vagrant up --provider=libvirt

# Запустите Ansible плейбук
cd ansible
ansible-playbook -i hosts provision.yml


    Подключитесь к master-серверу:

bash

vagrant ssh node1
sudo -u postgres psql

    Проверьте статус репликации на master:

sql

SELECT * FROM pg_stat_replication;

    Проверьте статус на slave:

bash

vagrant ssh node2
sudo -u postgres psql -c "SELECT * FROM pg_stat_wal_receiver;"

    Создайте тестовые данные на master и проверьте их на slave:

sql

-- На master
CREATE DATABASE test_replication;
\c test_replication
CREATE TABLE test_table (id serial, data text);
INSERT INTO test_table (data) VALUES ('test data');

-- На slave
\c test_replication
SELECT * FROM test_table;

Пример восстановления базы данных:
bash

# На barman сервере
sudo -u barman barman recover node1 <backup_id> /path/to/recovery

# Или прямо на PostgreSQL сервер
sudo -u barman barman recover --remote-ssh-command "ssh postgres@node1" node1 <backup_id> /var/lib/pgsql/14/data/

# Проверка репликации
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"

# Проверка слотов репликации
sudo -u postgres psql -c "SELECT * FROM pg_replication_slots;"

# Проверка Barman
sudo -u barman barman check node1
sudo -u barman barman status node1

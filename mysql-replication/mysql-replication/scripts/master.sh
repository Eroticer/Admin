#!/bin/bash

# Установка Percona Server
yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
percona-release setup ps80
yum install -y percona-server-server

# Копирование конфигурации
cp /vagrant/config/master.cnf /etc/my.cnf.d/server.cnf

# Запуск MySQL
systemctl start mysqld
systemctl enable mysqld

# Получение временного пароля
TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')

# Смена пароля root
mysql --connect-expired-password -uroot -p"$TEMP_PASSWORD" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyStrongPass!123';" 2>/dev/null

# Создание базы данных и загрузка дампа
mysql -uroot -p'MyStrongPass!123' -e "CREATE DATABASE bet;"
mysql -uroot -p'MyStrongPass!123' bet < /vagrant/bet.dmp

# Создание пользователя для репликации
mysql -uroot -p'MyStrongPass!123' -e "
CREATE USER 'repl'@'192.168.56.151' IDENTIFIED BY 'ReplPass!123';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.168.56.151';
FLUSH PRIVILEGES;
"

# Дамп базы данных (игнорируя ненужные таблицы)
mysqldump -uroot -p'MyStrongPass!123' --databases bet --ignore-table=bet.events_on_demand --ignore-table=bet.v_same_event --master-data=2 --gtid > /tmp/master_dump.sql

# Разрешение подключений с slave
firewall-cmd --permanent --add-service=mysql
firewall-cmd --reload

echo "Master setup completed!"
echo "GTID executed:"
mysql -uroot -p'MyStrongPass!123' -e "SELECT @@GLOBAL.GTID_EXECUTED;"

#!/bin/bash

# Установка Percona Server
yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
percona-release setup ps80
yum install -y percona-server-server

# Копирование конфигурации
cp /vagrant/config/slave.cnf /etc/my.cnf.d/server.cnf

# Запуск MySQL
systemctl start mysqld
systemctl enable mysqld

# Ожидание готовности мастера
sleep 30

# Получение временного пароля
TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')

# Смена пароля root
mysql --connect-expired-password -uroot -p"$TEMP_PASSWORD" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyStrongPass!123';" 2>/dev/null

# Копирование дампа с мастера
scp -o StrictHostKeyChecking=no vagrant@192.168.56.150:/tmp/master_dump.sql /tmp/

# Восстановление дампа
mysql -uroot -p'MyStrongPass!123' < /tmp/master_dump.sql

# Получение GTID из дампа
GTID_PURGED=$(grep "SET @@GLOBAL.GTID_PURGED" /tmp/master_dump.sql | sed "s/SET @@GLOBAL.GTID_PURGED='//" | sed "s/';//")

# Настройка репликации
mysql -uroot -p'MyStrongPass!123' -e "
STOP SLAVE;
RESET SLAVE ALL;
SET GLOBAL gtid_purged='$GTID_PURGED';
CHANGE MASTER TO 
MASTER_HOST='192.168.56.150',
MASTER_USER='repl',
MASTER_PASSWORD='ReplPass!123',
MASTER_AUTO_POSITION=1;
START SLAVE;
"

# Проверка статуса репликации
echo "Slave setup completed!"
echo "Slave status:"
mysql -uroot -p'MyStrongPass!123' -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Last_Error"

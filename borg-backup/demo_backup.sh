#!/bin/bash
echo "=== Демонстрация работы Borg Backup ==="

echo "1. Проверяем статус виртуальных машин..."
vagrant status

echo "2. Проверяем systemd таймер..."
vagrant ssh client-machine -c "sudo systemctl status borg-backup.timer"

echo "3. Запускаем бэкап вручную..."
vagrant ssh client-machine -c "sudo /opt/backup/backup.sh"

echo "4. Показываем список бэкапов..."
vagrant ssh client-machine -c "export BORG_PASSPHRASE='Otus1234' && export BORG_RSH='ssh -i /home/vagrant/.ssh/borg_key -o StrictHostKeyChecking=no' && borg list borg@192.168.100.160:~/backup/"

echo "5. Показываем информацию о репозитории..."
vagrant ssh client-machine -c "export BORG_PASSPHRASE='Otus1234' && export BORG_RSH='ssh -i /home/vagrant/.ssh/borg_key -o StrictHostKeyChecking=no' && borg info borg@192.168.100.160:~/backup/"

echo "6. Показываем логи..."
vagrant ssh client-machine -c "sudo tail -n 10 /var/log/borg-backup.log"

echo "7. Проверяем содержимое backup директории на сервере..."
vagrant ssh client-machine -c "ssh -i /home/vagrant/.ssh/borg_key borg@192.168.100.160 'ls -la ~/backup/'"

echo "=== Демонстрация завершена ==="

#!/bin/bash
echo "Finishing Borg Backup setup..."

# Копируем backup скрипт
vagrant ssh client-machine -c "sudo mkdir -p /opt/backup"
vagrant ssh client-machine -c "sudo cp /vagrant/scripts/backup.sh /opt/backup/backup.sh"
vagrant ssh client-machine -c "sudo chmod +x /opt/backup/backup.sh"

# Обновляем пути в скрипте - ИСПРАВЛЯЕМ на домашнюю директорию borg
vagrant ssh client-machine -c "sudo sed -i 's|^SSH_KEY=.*|SSH_KEY=\"/home/vagrant/.ssh/borg_key\"|' /opt/backup/backup.sh"
vagrant ssh client-machine -c "sudo sed -i 's|^REPO=.*|REPO=\"borg@192.168.100.160:~/backup/\"|' /opt/backup/backup.sh"
vagrant ssh client-machine -c "sudo sed -i 's|^export BORG_PASSPHRASE=.*|export BORG_PASSPHRASE=\"Otus1234\"|' /opt/backup/backup.sh"

# Создаем systemd службу
vagrant ssh client-machine -c "sudo tee /etc/systemd/system/borg-backup.service > /dev/null << 'END'
[Unit]
Description=Borg Backup
After=network-online.target

[Service]
Type=oneshot
User=root
Environment=\"BORG_RSH=ssh -i /home/vagrant/.ssh/borg_key -o StrictHostKeyChecking=no\"
Environment=\"BORG_PASSPHRASE=Otus1234\"
ExecStart=/opt/backup/backup.sh

[Install]
WantedBy=multi-user.target
END"

# Создаем таймер
vagrant ssh client-machine -c "sudo tee /etc/systemd/system/borg-backup.timer > /dev/null << 'END'
[Unit]
Description=Borg Backup Timer
Requires=borg-backup.service

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
END"

# Запускаем службу
vagrant ssh client-machine -c "sudo systemctl daemon-reload"
vagrant ssh client-machine -c "sudo systemctl enable borg-backup.timer"
vagrant ssh client-machine -c "sudo systemctl start borg-backup.timer"

echo "Setup completed! Running test backup..."

# Тестовый бэкап
vagrant ssh client-machine -c "sudo /opt/backup/backup.sh"

echo "Checking status..."
vagrant ssh client-machine -c "sudo systemctl status borg-backup.timer"
vagrant ssh client-machine -c "BORG_PASSPHRASE='Otus1234' borg list borg@192.168.100.160:~/backup/"

echo "=== Borg Backup Setup Completed Successfully ==="

# Admin

## Домашние задания

<details>
    <summary>2. LVM-1,2</summary>
<b>Описание задания</b>

1. Настроить LVM в Ubuntu 24.04 Server
2. Создать Physical Volume, Volume Group и Logical Volume
3. Отформатировать и смонтировать файловую систему
4. Расширить файловую систему за счёт нового диска
5. Выполнить resize
6. Проверить корректность работы

**Смотрим блочные устройства**

```bash
kirill@ubuntusrv:~$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   25G  0 disk 
├─sda1   8:1    0    1M  0 part 
└─sda2   8:2    0   25G  0 part /
sdb      8:16   0 20,8G  0 disk 
sdc      8:32   0   11G  0 disk 
sdd      8:48   0  5,4G  0 disk 
sde      8:64   0  5,4G  0 disk 
sr0     11:0    1 1024M  0 rom  
```

**Создаем logical volume(lv_root) в volume groupe(vg_root) на physical volume(sdb)**

```bash
kirill@ubuntusrv:~$ sudo pvcreate /dev/sdb
[sudo] password for kirill: 
  Physical volume "/dev/sdb" successfully created.
kirill@ubuntusrv:~$ sudo vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created
kirill@ubuntusrv:~$ sudo lvcreate -n lv_root -l +100%FREE /dev/vg_root 
  Logical volume "lv_root" created.
```

**Создаём файловую систему в lv_root, монтируем ее в каталог /mnt  и копируем все из корня в нее**

```bash
kirill@ubuntusrv:~$ sudo mkfs.ext4 /dev/vg_root/lv_root
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 5448704 4k blocks and 1362720 inodes
Filesystem UUID: 303d2ecf-3a3d-47c9-8056-a7368ceda85d
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208, 
	4096000

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done   

kirill@ubuntusrv:~$ sudo mount /dev/vg_root/lv_root /mnt
kirill@ubuntusrv:~$ rsync -avxHAX --progress / /mnt/ # a(сохраняет все права и метки) v(отображает все копируемые файлы) x(не затрагивает другие фс) H(сохраняет жесткие ссылки) A(сохраняет все права) X(сохраняет расширенные атрибуты) --progress(отображает линию прогресса)
sent 2.492.961.262 bytes  received 1.582.425 bytes  17.629.284,01 bytes/sec
total size is 2.490.743.922  speedup is 1,00
kirill@ubuntusrv:~$ ls /mnt
bin                dev   lib64              mnt   run                 srv  var
bin.usr-is-merged  etc   lib.usr-is-merged  opt   sbin                sys
boot               home  lost+found         proc  sbin.usr-is-merged  tmp
cdrom              lib   media              root  snap                usr
```

**Создаем критические папки в /mnt и монтируем их с системными. Далее делаем /mnt корневым каталогом и создаем новый grub-файл. После чего обновляем initramfs это необходимо для старта системы**

```bash
kirill@ubuntusrv:~$ sudo bash -c 'mkdir -p /mnt/{proc,sys,dev,run,boot}; for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind "$i" "/mnt$i"; done'
kirill@ubuntusrv:~$ sudo chroot /mnt/
root@ubuntusrv:/# grub-mkconfig -o /boot/grub/grub.cfg
Sourcing file `/etc/default/grub'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.8.0-60-generic
Found initrd image: /boot/initrd.img-6.8.0-60-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done
root@ubuntusrv:/# update-initramfs -u
update-initramfs: Generating /boot/initrd.img-6.8.0-60-generic
root@ubuntusrv:/# exit
exit
kirill@ubuntusrv:~$ sudo reboot
```

**Проверяем после reboot**

```bash
kirill@192.168.1.18's password: 
Welcome to Ubuntu 24.04.2 LTS (GNU/Linux 6.8.0-60-generic x86_64)
kirill@ubuntusrv:~$ lsblk
NAME              MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                 8:0    0   25G  0 disk 
├─sda1              8:1    0    1M  0 part 
└─sda2              8:2    0   25G  0 part 
sdb                 8:16   0 20,8G  0 disk 
└─vg_root-lv_root 252:0    0 20,8G  0 lvm  /
sdc                 8:32   0   11G  0 disk 
sdd                 8:48   0  5,4G  0 disk 
sde                 8:64   0  5,4G  0 disk 
sr0                11:0    1 1024M  0 rom  
```

**Удаляем LV(начальный*) и создем его же размером 8G и делаем все то же самое, что выше**
*Я забыл в начале создать LVM на sda2

```bash
kirill@ubuntusrv:~$ lvremove /dev/ubuntu-vg/ubuntu-lv
Do you really want to remove and DISCARD active logical volume ubuntu-vg/ubuntu-lv? [y/n]: y
  Logical volume "ubuntu-lv" successfully removed.

kirill@ubuntusrv:~$ lvcreate -n ubuntu-vg/ubuntu-lv -L 8G /dev/ubuntu-vg
WARNING: ext4 signature detected on /dev/ubuntu-vg/ubuntu-lv at offset 1080. Wipe it? [y/n]: y
  Wiping ext4 signature on /dev/ubuntu-vg/ubuntu-lv.
  Logical volume "ubuntu-lv" created.
```

**Далее пробуем создать зеркало из sdc, sdd**

```bash
kirill@ubuntusrv:~$ sudo pvcreate /dev/sdc /sev/sdd
  No device found for /sev/sdd.
  Physical volume "/dev/sdc" successfully created.
kirill@ubuntusrv:~$ sudo pvcreate /dev/sdd
  Physical volume "/dev/sdd" successfully created.
kirill@ubuntusrv:~$ sudo vgcreate vg_var /dev/sdc /dev/sdd
  Volume group "vg_var" successfully created
kirill@ubuntusrv:~$ sudo lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952,00 MiB
  Logical volume "lv_var" created.
```

**Создаем файловую систему**

```bash
kirill@ubuntusrv:~$ sudo mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 243712 4k blocks and 60928 inodes
Filesystem UUID: afaafe5d-60ea-4b81-bbad-ff990f404d08
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done
```

**Далее монтируем LV в /mnt и копируем все файлы. Перемещаем старый var в отдельную папку. Размонтируем м монтируем LV в /var. Извлекаем uid и добавляем его в конец fstab**

```bash
kirill@ubuntusrv:~$ sudo mount /dev/vg_var/lv_var /mnt
kirill@ubuntusrv:~$ sudo cp  -aR /var/* /mnt/
kirill@ubuntusrv:~$ sudo mkdir /tmp/oldvar && sudo mv /var/* /tmp/oldvar
kirill@ubuntusrv:~$ sudo umount /mnt
kirill@ubuntusrv:~$ sudo mount /dev/vg_var/lv_var /var 
kirill@ubuntusrv:~$ sudo bash -c 'echo "`blkid | grep var: | awk \"{print \$2}\"` /var ext4 defaults 0 0" >> /etc/fstab'
kirill@ubuntusrv:~$ lvremove /dev/vg_root/lv_root
kirill@ubuntusrv:~$ vgremove /dev/vg_root
kirill@ubuntusrv:~$ pvremove /dev/sdb
```
**Работа со снэпшотами**
**Создаем 20файлов в /mnt**

```bash
kirill@ubu:~$ ls /mnt
bin                dev   lib64              mnt   run                 srv  var
bin.usr-is-merged  etc   lib.usr-is-merged  opt   sbin                sys
boot               home  lost+found         proc  sbin.usr-is-merged  tmp
cdrom              lib   media              root  snap                usr
kirill@ubu:~$ ls
kirill@ubu:~$ lsblk
NAME                MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                   8:0    0   25G  0 disk 
├─sda1                8:1    0    1M  0 part 
└─sda2                8:2    0   25G  0 part /
sdb                   8:16   0  7,2G  0 disk 
└─vg--home-lv--home 252:0    0  5,8G  0 lvm  /mnt
sdc                   8:32   0  8,2G  0 disk 
sr0                  11:0    1 1024M  0 rom  
kirill@ubu:~$ sudo touch /mnt/file{1..20}
kirill@ubu:~$ ls /mnt
bin                file11  file19  file8              mnt                 srv
bin.usr-is-merged  file12  file2   file9              opt                 sys
boot               file13  file20  home               proc                tmp
cdrom              file14  file3   lib                root                usr
dev                file15  file4   lib64              run                 var
etc                file16  file5   lib.usr-is-merged  sbin
file1              file17  file6   lost+found         sbin.usr-is-merged
file10             file18  file7   media              snap
```

**Делаем снэпшот и удаляем половину файлов** 

```bash
kirill@ubu:~$ sudo lvcreate -L 100MB -s -n mnt_sanp /dev/vg-home/lv-home
  Logical volume "mnt_sanp" created.
kirill@ubu:~$ lsblk
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                        8:0    0   25G  0 disk 
├─sda1                     8:1    0    1M  0 part 
└─sda2                     8:2    0   25G  0 part /
sdb                        8:16   0  7,2G  0 disk 
├─vg--home-lv--home-real 252:1    0  5,8G  0 lvm  
│ ├─vg--home-lv--home    252:0    0  5,8G  0 lvm  /mnt
│ └─vg--home-mnt_sanp    252:3    0  5,8G  0 lvm  
└─vg--home-mnt_sanp-cow  252:2    0  100M  0 lvm  
  └─vg--home-mnt_sanp    252:3    0  5,8G  0 lvm  
sdc                        8:32   0  8,2G  0 disk 
sr0                       11:0    1 1024M  0 rom  
kirill@ubu:~$ sudo rm -f /mnt/file{11..20}
```

***Отсоединяем /mnt, мержим со снэпом и монтируем в /mnt**

```bash
kirill@ubu:~$ sudo umount /mnt
kirill@ubu:~$ lsblk
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                        8:0    0   25G  0 disk 
├─sda1                     8:1    0    1M  0 part 
└─sda2                     8:2    0   25G  0 part /
sdb                        8:16   0  7,2G  0 disk 
├─vg--home-lv--home-real 252:1    0  5,8G  0 lvm  
│ ├─vg--home-lv--home    252:0    0  5,8G  0 lvm  
│ └─vg--home-mnt_sanp    252:3    0  5,8G  0 lvm  
└─vg--home-mnt_sanp-cow  252:2    0  100M  0 lvm  
  └─vg--home-mnt_sanp    252:3    0  5,8G  0 lvm  
sdc                        8:32   0  8,2G  0 disk 
sr0                       11:0    1 1024M  0 rom  
kirill@ubu:~$ sudo lvconvert --merge /dev/vg-home/mnt_sanp
  Merging of volume vg-home/mnt_sanp started.
  vg-home/lv-home: Merged: 100,00%
kirill@ubu:~$ lsblk
NAME                MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                   8:0    0   25G  0 disk 
├─sda1                8:1    0    1M  0 part 
└─sda2                8:2    0   25G  0 part /
sdb                   8:16   0  7,2G  0 disk 
└─vg--home-lv--home 252:0    0  5,8G  0 lvm  
sdc                   8:32   0  8,2G  0 disk 
sr0                  11:0    1 1024M  0 rom  
kirill@ubu:~$ sudo mount /dev/mapper/vg--home-lv--home /mnt
```

**Проверяем и видим то все востановилось**

```bash
kirill@ubu:~$ ls -al /mnt
total 104
drwxr-xr-x  23 root root  4096 мая 20 20:59 .
drwxr-xr-x  23 root root  4096 мая 20 20:17 ..
lrwxrwxrwx   1 root root     7 апр 22  2024 bin -> usr/bin
drwxr-xr-x   2 root root  4096 фев 26  2024 bin.usr-is-merged
drwxr-xr-x   3 root root  4096 мая 20 20:22 boot
dr-xr-xr-x   2 root root  4096 мая 20 20:16 cdrom
drwxr-xr-x   2 root root  4096 мая 20 20:46 dev
drwxr-xr-x 108 root root  4096 мая 20 20:37 etc
-rw-r--r--   1 root root     0 мая 20 20:59 file1
-rw-r--r--   1 root root     0 мая 20 20:59 file10
-rw-r--r--   1 root root     0 мая 20 20:59 file11
-rw-r--r--   1 root root     0 мая 20 20:59 file12
-rw-r--r--   1 root root     0 мая 20 20:59 file13
-rw-r--r--   1 root root     0 мая 20 20:59 file14
-rw-r--r--   1 root root     0 мая 20 20:59 file15
-rw-r--r--   1 root root     0 мая 20 20:59 file16
-rw-r--r--   1 root root     0 мая 20 20:59 file17
-rw-r--r--   1 root root     0 мая 20 20:59 file18
-rw-r--r--   1 root root     0 мая 20 20:59 file19
-rw-r--r--   1 root root     0 мая 20 20:59 file2
-rw-r--r--   1 root root     0 мая 20 20:59 file20
-rw-r--r--   1 root root     0 мая 20 20:59 file3
-rw-r--r--   1 root root     0 мая 20 20:59 file4
-rw-r--r--   1 root root     0 мая 20 20:59 file5
-rw-r--r--   1 root root     0 мая 20 20:59 file6
-rw-r--r--   1 root root     0 мая 20 20:59 file7
-rw-r--r--   1 root root     0 мая 20 20:59 file8
-rw-r--r--   1 root root     0 мая 20 20:59 file9
drwxr-xr-x   3 root root  4096 мая 20 20:29 home
lrwxrwxrwx   1 root root     7 апр 22  2024 lib -> usr/lib
lrwxrwxrwx   1 root root     9 апр 22  2024 lib64 -> usr/lib64
drwxr-xr-x   2 root root  4096 фев 26  2024 lib.usr-is-merged
drwx------   2 root root 16384 мая 20 20:17 lost+found
drwxr-xr-x   2 root root  4096 фев 16 20:51 media
drwxr-xr-x   2 root root  4096 мая 20 20:47 mnt
drwxr-xr-x   2 root root  4096 фев 16 20:51 opt
dr-xr-xr-x   2 root root  4096 мая 20 20:41 proc
drwx------   3 root root  4096 мая 20 20:28 root
drwxr-xr-x   2 root root  4096 мая 20 20:42 run
lrwxrwxrwx   1 root root     8 апр 22  2024 sbin -> usr/sbin
drwxr-xr-x   2 root root  4096 авг 22  2024 sbin.usr-is-merged
drwxr-xr-x   2 root root  4096 мая 20 20:29 snap
drwxr-xr-x   2 root root  4096 фев 16 20:51 srv
dr-xr-xr-x   2 root root  4096 мая 20 20:41 sys
drwxrwxrwt  12 root root  4096 мая 20 20:42 tmp
drwxr-xr-x  12 root root  4096 фев 16 20:51 usr
drwxr-xr-x  13 root root  4096 мая 20 20:29 var
```
</details>
<details>
    <summary>4. NFS</summary>

**Устанавливаем пакеты на пк и сервер**
```bash
sudo apt install nfs-kernel-server для сервера и sudo apt install nfs-common для клиента
```

**проверяем открытые порты 2049 и 111 на сервере**
```bash
kirill@ubuntupc:~$ ss -tnplu
```

**Создаем дирректорию для дальнейшего экспорта**
```bash
kirill@ubuntupc:~$ cd /etc
kirill@ubuntupc:/etc$ sudo mkdir -p /srv/share/upload #-p проверяет наличие уже созданной такой папки
```

**настраиваем права доступа**
```bash
kirill@ubuntupc:/etc$ sudo chown -R nobody:nogroup /srv/share # рекурсивно меняем группу и пользователя на минимальные права
kirill@ubuntupc:/etc$ sudo chmod 0777 /srv/share/upload # устанавливаем максимальные права на /upload
```

**Делаем запись на разрешения экспорта**
```bash
kirill@ubuntupc:/etc$ sudo vim /etc/exports
#и добавляем в конец строчку
#/srv/share 192.168.50.11/32(rw,sync,root_squash)
```

**Перезагружаем таблицу экспорта**
```bash
kirill@ubuntupc:/etc$ sudo exportfs -r
exportfs: /etc/exports [1]: Neither 'subtree_check' or 'no_subtree_check' specified for export "192.168.1.6/32:/srv/share/".
  Assuming default behaviour ('no_subtree_check').
  NOTE: this default has changed since nfs-utils version 1.0.x
```

**выводим таблицу для проверки**
```bash
kirill@ubuntupc:/etc$ sudo exportfs -s
/srv/share  192.168.1.6/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```

**<b>Настраиваем клиента</b>**
```bash
Добавляем запись в fstab
kirill@ubuntu:~$ sudo bash -c " echo '192.168.1.7:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0' >> /etc/fstab"
```

**в данном случае происходит автоматическая генерация systemd units в каталоге /run/systemd/generator/, которые производят монтирование при первом обращении к каталогу /mnt**
```bash
kirill@ubuntu:~$ systemctl daemon-reload
==== AUTHENTICATING FOR org.freedesktop.systemd1.reload-daemon ====
Чтобы заставить systemd перечитать конфигурацию, необходимо пройти аутентификацию.
Authenticating as: kirill
Password: 
==== AUTHENTICATION COMPLETE ====
kirill@ubuntu:~$ systemctl restart remote-fs.target
==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ====
Чтобы перезапустить «remote-fs.target», необходимо пройти аутентификацию.
Authenticating as: kirill
Password: 
==== AUTHENTICATION COMPLETE ====

kirill@ubuntu:~$ ls /mnt #ls/mnt потому что монтируется только при обращении из за x-systemd.automount
upload
kirill@ubuntu:~$ mount | grep mnt
nsfs on /run/snapd/ns/snapd-desktop-integration.mnt type nsfs (rw)
nsfs on /run/snapd/ns/firmware-updater.mnt type nsfs (rw)
systemd-1 on /mnt type autofs (rw,relatime,fd=90,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=25751)
192.168.1.7:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.1.7,mountvers=3,mountport=54122,mountproto=udp,local_lock=none,addr=192.168.1.7)
```

**Проверяем работоспособность**
```bash
#server
kirill@ubuntupc:/srv/share$ sudo touch checkfile
[sudo] password for kirill: 
kirill@ubuntupc:/srv/share$ 
checkfile upload

#client
kirill@ubuntu:~$ ls /mnt
checkfile  upload
kirill@ubuntu:~$ sudo touch /mnt/client_file
[sudo] пароль для kirill: 
kirill@ubuntu:~$ ls /mnt
checkfile  client_file  upload
kirill@ubuntu:~$ sudo reboot

Broadcast message from root@ubuntu on pts/2 (Mon 2025-05-26 19:53:35 UTC):

The system will reboot now!

eroticer@eroticer-Nitro-AN515-55:~$ ssh kirill@192.168.1.6
kirill@192.168.1.6's password: 
Welcome to Ubuntu 24.04.2 LTS (GNU/Linux 6.11.0-26-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

Расширенное поддержание безопасности (ESM) для Applications выключено.

110 обновлений может быть применено немедленно.
Чтобы просмотреть дополнительные обновления выполните: apt list --upgradable

Включите ESM Apps для получения дополнительных будущих обновлений безопасности.
Смотрите https://ubuntu.com/esm или выполните: sudo pro status

Last login: Sun May 25 20:11:56 2025 from 192.168.1.4
kirill@ubuntu:~$ ls /mnt
checkfile  client_file  upload
```
```bash
#server

kirill@ubuntupc:/srv/share$ sudo reboot

Broadcast message from root@ubuntupc on pts/1 (Mon 2025-05-26 20:00:40 UTC):

The system will reboot now!

kirill@ubuntupc:/srv/share$ Connection to 192.168.1.7 closed by remote host.
Connection to 192.168.1.7 closed.
eroticer@eroticer-Nitro-AN515-55:~$ ssh kirill@192.168.1.7
kirill@192.168.1.7's password: 
Welcome to Ubuntu 24.04.2 LTS (GNU/Linux 6.8.0-60-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Пн 26 мая 2025 20:01:58 UTC

  System load:             1.82
  Usage of /:              10.4% of 24.44GB
  Memory usage:            2%
  Swap usage:              0%
  Processes:               136
  Users logged in:         0
  IPv4 address for enp0s3: 192.168.1.7
  IPv6 address for enp0s3: 2a00:1370:8192:5f39:a00:27ff:fe13:8c55


Расширенное поддержание безопасности (ESM) для Applications выключено.

63 обновления может быть применено немедленно.
Чтобы просмотреть дополнительные обновления выполните: apt list --upgradable

Включите ESM Apps для получения дополнительных будущих обновлений безопасности.
Смотрите https://ubuntu.com/esm или выполните: sudo pro status


Last login: Sun May 25 20:11:05 2025 from 192.168.1.4
kirill@ubuntupc:~$ ls /srv/share/
checkfile  client_file  upload
```
</details>
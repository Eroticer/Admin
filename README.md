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
    <summary>3. ZFS</summary>
asasasas
</details>
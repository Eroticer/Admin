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
</details>
<details>
    <summary>3. ZFS</summary>
asasasas
</details>
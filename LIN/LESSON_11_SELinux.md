Домашнее задание
Практика с SELinux

Цель:
работать с SELinux: диагностировать проблемы и модифицировать политики SELinux для корректной работы приложений, если это требуется;

Что нужно сделать?

1. Запустить nginx на нестандартном порту 3-мя разными способами:
переключатели setsebool;
добавление нестандартного порта в имеющийся тип;
формирование и установка модуля SELinux.
К сдаче:
README с описанием каждого решения (скриншоты и демонстрация приветствуются).

<<<<<<< HEAD
2. Обеспечить работоспособность приложения при включенном osboxes.

развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/osboxes_dns_problems;
=======
2. Обеспечить работоспособность приложения при включенном selinux.

развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems;
>>>>>>> 1b0aecf26cb2b4c13c0e05b720cafe914751ee5c
выяснить причину неработоспособности механизма обновления зоны (см. README);
предложить решение (или решения) для данной проблемы;
выбрать одно из решений для реализации, предварительно обосновав выбор;
реализовать выбранное решение и продемонстрировать его работоспособность.


#######################################

1) Первое задание выполнял без vagrant, тк вложенная виртуализация не функционирует. Сам изменил порты на котором работает nginx и пробросил порты в гипервизоре.

// тк SELinux включен по умолчанию на Fedora OS, то nginx не запущен и находится в состоянии failed

// перед началом работы выключаем фаерфолы
<<<<<<< HEAD
[root@osboxes ~]# systemctl stop firewalld
[root@osboxes ~]# systemctl stop ufw

// Проверим режим работы SELinux 
[root@osboxes ~]# getenforce 
Enforcing

// находим в логах информацию о блокировании порта и копируем временную метку в команду
[root@osboxes ~]# grep 1743229391.265:775 /var/log/audit/audit.log | audit2why
=======
[root@selinux ~]# systemctl stop firewalld
[root@selinux ~]# systemctl stop ufw

// Проверим режим работы SELinux 
[root@selinux ~]# getenforce 
Enforcing

// находим в логах информацию о блокировании порта и копируем временную метку в команду
[root@selinux ~]# grep 1743229391.265:775 /var/log/audit/audit.log | audit2why
>>>>>>> 1b0aecf26cb2b4c13c0e05b720cafe914751ee5c

        Was caused by:
        The boolean nis_enabled was set incorrectly.
        Description:
        Allow nis to enabled


        Allow access by executing:
        # setsebool -P nis_enabled 1

// видим, что предлагается для добавления доступа ввести команду
<<<<<<< HEAD
[root@osboxes ~]# setsebool -P nis_enabled on

// стартуем nginx и получаем ответ об успешном запуске(видим это в браузере http://localhost:4881)
[root@osboxes ~]# systemctl restart nginx

// вернём запрет работы nginx на порту 4881 обратно. Для этого отключим nis_enabled
[root@osboxes ~]# setsebool -P nis_enabled off

// Видно, что для нужного типа порта (http_port_t) не добавлен 4881
[root@osboxes ~]# semanage port -l | grep http
=======
[root@selinux ~]# setsebool -P nis_enabled on

// стартуем nginx и получаем ответ об успешном запуске(видим это в браузере http://localhost:4881)
[root@selinux ~]# systemctl restart nginx

// вернём запрет работы nginx на порту 4881 обратно. Для этого отключим nis_enabled
[root@selinux ~]# setsebool -P nis_enabled off

// Видно, что для нужного типа порта (http_port_t) не добавлен 4881
[root@selinux ~]# semanage port -l | grep http
>>>>>>> 1b0aecf26cb2b4c13c0e05b720cafe914751ee5c
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989

// добавляем в список разрешенных к http_port_t 4881 порт 
<<<<<<< HEAD
[root@osboxes ~]# semanage port -a -t http_port_t -p tcp 4881
[root@osboxes ~]# semanage port -l | grep http
=======
[root@selinux ~]# semanage port -a -t http_port_t -p tcp 4881
[root@selinux ~]# semanage port -l | grep http
>>>>>>> 1b0aecf26cb2b4c13c0e05b720cafe914751ee5c
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989

// перезапускаем nginx и убеждаемся, что веб-страница снова доступна, а значит SELinux пропускает 4881 порт
<<<<<<< HEAD
[root@osboxes ~]# systemctl restart nginx

// удалить ненужный порт аналогичной командой с другим флагом (вместо -a (add) -d (deny))
[root@osboxes ~]# semanage port -d -t http_port_t -p tcp 4881
[root@osboxes ~]# semanage port -l | grep  http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
[root@osboxes ~]# systemctl restart nginx
=======
[root@selinux ~]# systemctl restart nginx

// удалить ненужный порт аналогичной командой с другим флагом (вместо -a (add) -d (deny))
[root@selinux ~]# semanage port -d -t http_port_t -p tcp 4881
[root@selinux ~]# semanage port -l | grep  http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
[root@selinux ~]# systemctl restart nginx
>>>>>>> 1b0aecf26cb2b4c13c0e05b720cafe914751ee5c
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.

// Воспользуемся утилитой audit2allow для того, чтобы на основе логов SELinux сделать модуль, разрешающий работу nginx на нестандартном порту: 
grep nginx /var/log/audit/audit.log | audit2allow -M nginx
<<<<<<< HEAD
[root@osboxes ~]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
=======
[root@selinux ~]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
>>>>>>> 1b0aecf26cb2b4c13c0e05b720cafe914751ee5c
******************** IMPORTANT ***********************
To make this policy package active, execute:


semodule -i nginx.pp

// вводим предложенную команду для добавления вновь созданного модуля в список разрешенных модулей
<<<<<<< HEAD
[root@osboxes ~]# semodule -i nginx.pp

// посмотрим, что модуль добавился
[root@osboxes ~]# semodule -l | grep nginx
nginx

// перезапускаем nginx и убеждаемся, что веб-страница снова доступна, а значит SELinux пропускает 4881 порт
[root@osboxes ~]# systemctl restart nginx

// для удаления модуля воспользуемся командой: semodule -r nginx
[root@osboxes ~]# semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).
[root@osboxes ~]# systemctl restart nginx
=======
[root@selinux ~]# semodule -i nginx.pp

// посмотрим, что модуль добавился
[root@selinux ~]# semodule -l | grep nginx
nginx

// перезапускаем nginx и убеждаемся, что веб-страница снова доступна, а значит SELinux пропускает 4881 порт
[root@selinux ~]# systemctl restart nginx

// для удаления модуля воспользуемся командой: semodule -r nginx
[root@selinux ~]# semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).
[root@selinux ~]# systemctl restart nginx
>>>>>>> 1b0aecf26cb2b4c13c0e05b720cafe914751ee5c
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.


#######################################

2) 
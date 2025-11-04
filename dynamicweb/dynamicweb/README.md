# Динамический веб-стек с Docker Compose

Этот проект разворачивает полный веб-стек для разработки с использованием:
- Nginx в качестве обратного прокси
- WordPress с PHP-FPM
- Django Python приложение
- Node.js приложение
- MySQL базу данных

## Предварительные требования

- Vagrant
- libvirt с KVM
- Ansible

## Быстрый старт

1. Клонируйте этот репозиторий
2. Запустите развертывание:

```bash
vagrant up --provider=libvirt

    WordPress: http://localhost:8083

    Django: http://localhost:8081

    Node.js: http://localhost:8082

Проверка работоспособности

    Проверьте, что все контейнеры запущены:

bash

vagrant ssh
docker ps

    Убедитесь, что сервисы доступны:

bash

curl http://localhost:8081
curl http://localhost:8082
curl http://localhost:8083

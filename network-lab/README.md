# Сетевая лаборатория на Libvirt/KVM с Rocky Linux 9

## Описание
Сложная сетевая лаборатория с маршрутизацией и NAT, развернутая на базе Libvirt/KVM с Rocky Linux 9.

## Архитектура сети
- **inetRouter** - шлюз в интернет с NAT
- **centralRouter** - центральный маршрутизатор  
- **office1Router**, **office2Router** - маршрутизаторы офисов
- **centralServer**, **office1Server**, **office2Server** - серверы в соответствующих сетях

## Быстрый старт

### Предварительные требования
```bash
# Установка необходимых пакетов
sudo apt update
sudo apt install -y vagrant libvirt-daemon-system libvirt-clients \
    qemu-kvm qemu-utils bridge-utils virt-manager \
    ansible

# Установка плагина vagrant-libvirt
vagrant plugin install vagrant-libvirt




./create-networks.sh

# Запустить машины
vagrant up --provider=libvirt

# Настроить сеть
./setup-rocky-network.sh
./fix-routes.sh
./enable-forwarding.sh
./setup-nat.sh

# Протестировать
./final-test.sh

#!/bin/bash
echo "Manual PXE Server Setup"

apt update
apt install -y dnsmasq apache2 wget cloud-image-utils

mkdir -p /srv/tftp/amd64/pxelinux.cfg /srv/images /srv/ks


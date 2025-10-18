#!/bin/bash
wget -O /srv/images/ubuntu-22.04-live-server-amd64.iso \
  http://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso

wget -O /tmp/netboot.tar.gz \
  http://archive.ubuntu.com/ubuntu/dists/jammy/main/installer-amd64/current/images/netboot/netboot.tar.gz

tar -xzf /tmp/netboot.tar.gz -C /srv/tftp/amd64


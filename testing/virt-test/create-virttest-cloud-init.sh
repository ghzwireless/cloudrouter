#!/usr/bin/env bash

cat > user-data << EOF
#cloud-config
users:
  - name: cloudrouter
    gecos: CloudRouter
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    groups: wheel,adm,systemd-journal
    lock-passwd: False
    passwd: $6$hceCszYiXSJJPrIU$rEMlLg9bR/a0q8eWk.K..f.gZQkd/S8yH/8XknUpkR7u/HmaMif9HnQkcf.chHGqAJddW6s1X8C1iKtqdOEXv0 
    ssh_pwauth: True
    ssh_authorized_keys:
      - $(cat virttest_rsa.pub)
ssh_pwauth: True
EOF

cat > meta-data << EOF
instance-id: cloudrouter
local-hostname: cloudrouter
EOF

genisoimage -quiet \
        -output virttest-cloud-init.iso \
        -volid cidata \
        -joliet \
        -rock user-data meta-data
rm -f user-data meta-data

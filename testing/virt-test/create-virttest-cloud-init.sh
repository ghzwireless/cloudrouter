#!/usr/bin/env bash

cat > user-data << EOF
#cloud-config
ssh_pwauth: True
ssh_authorized_keys:
  - $(cat virttest_rsa.pub)
chpasswd:
  list: |
    root:123456
    cloudrouter:123456
  expire: False
runcmd:
  - shutdown -h now
EOF

cat > meta-data << EOF
instance-id: localhost
local-hostname: localhost
EOF

genisoimage -quiet \
        -output virttest-cloud-init.iso \
        -volid cidata \
        -joliet \
        -rock user-data meta-data
rm -f user-data meta-data

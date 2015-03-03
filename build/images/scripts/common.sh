#!/usr/bin/env bash

SYSCTL_CONF="/etc/sysctl.d/90-cloudrouter-default.conf"

cat > ${SYSCTL_CONF} << EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.ipv6.route.max_size = 50000
EOF

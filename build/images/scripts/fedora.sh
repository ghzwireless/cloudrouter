#!/usr/bin/env bash

# remove all fedora branding
rpm -qa | grep '^fedora-' | xargs -I {} rpm -e --nodeps {}


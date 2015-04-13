#!/usr/bin/env bash

# remove all feodra branding
rpm -qa | grep '^fedora-' | xargs -I {} rpm -e --nodeps {}


#!/usr/bin/env bash

PRODUCT="CloudRouter"
VERSION="1.0-beta"
FEDORA_BASE="20"

sudo livecd-creator \
    --verbose \
    --product="${PRODUCT} ${VERSION}" \
    --releasever="${FEDORA_BASE}" \
    --config=$(dirname "${BASH_SOURCE[0]}")/cloudrouter-live.ks \
    --fslabel="${PRODUCT}-${VERSION}-LiveCD" \
    --title "${PRODUCT} ${VERSION} LiveCD" \
    --cache=/var/cache/live

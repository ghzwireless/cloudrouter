#!/usr/bin/env bash

for ISSUE in "/etc/issue" "/etc/issue.net"; do
    [[ -f ${ISSUE} ]] && sed -i \
        's/Fedora.*/CloudRouter 1.0 Beta based on Fedora/' \
        ${ISSUE}
done


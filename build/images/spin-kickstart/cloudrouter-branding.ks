# cloudrouter-branding.ks

%packages
cloudrouter-release
-fedora-logos
-fedora-release
-fedora-release-notes
generic-release
generic-logos
generic-release-notes
%end

%post
# Fix release
RELEASE_NAME="CloudRouter 1.0 Beta (Fedora Remix)"

cat > /etc/cloudrouter-release << EOF
${RELEASE_NAME}
EOF

for ISSUE in "/etc/issue" "/etc/issue.net"; do
    cat > ${ISSUE} << EOF
${RELEASE_NAME}
Kernel \r on an \m (\l)

EOF
done

ln -sf /etc/redhat-release /etc/cloudrouter-release
ln -sf /etc/system-release /etc/cloudrouter-release

cat > /etc/os-release << EOF
NAME=CloudRouter
VERSION="1.0 Beta (Fedora Remix)"
ID=cloudrouter
VERSION_ID=1.0-beta
PRETTY_NAME="${RELEASE_NAME}"
ANSI_COLOR="0;34"
CPE_NAME="cpe:/o:cloudrouter:cloudrouter:1.0-beta"
HOME_URL="https://cloudrouter.org/"
BUG_REPORT_URL="https://issues.cloudrouter.org/"
EOF

# Fix grub entries
find /etc/ -maxdepth 1 -name "grub*.cfg" \
    -exec sed -i s/"menuentry 'Fedora.*'"/"menuentry 'CloudRouter 1.0 Beta (Fedora Remix)'"/ {} \; \
    -exec sed -i s/" rhgb "/" "/ {} \;
%end

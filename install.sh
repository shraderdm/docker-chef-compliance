#!/bin/sh
set -e -x

SERVER_VERSION="1.4.10-1"
SERVER_SHA1="56b7782d56aec0a164eae6928f1ff33e2c6a957d"
PACKAGE_NAME="chef-compliance_${SERVER_VERSION}_amd64.deb"

# Temporary work dir
tmpdir="`mktemp -d`"
cd "$tmpdir"

# Install prerequisites
export DEBIAN_FRONTEND=noninteractive
apt-get update -q --yes
apt-get install -q --yes logrotate vim-nox hardlink wget ca-certificates

# Download and install Chef's packages
wget -nv https://packages.chef.io/stable/ubuntu/16.04/${PACKAGE_NAME}
# mv /tmp/chef-compliance_1.4.10-1_amd64.deb .

sha1sum -c - <<EOF
${SERVER_SHA1} ${PACKAGE_NAME}
EOF
dpkg -i ${PACKAGE_NAME}

# Accept License
mkdir -p /var/opt/chef-compliance
mkdir -p /var/opt/chef-compliance/etc
mkdir -p /var/opt/chef-compliance/log
touch /var/opt/chef-compliance/.license.accepted

# Extra setup
rm -rf /etc/chef-compliance /var/log/chef-compliance
mkdir -p /etc/cron.hourly
ln -sfv /var/opt/chef-compliance/log /var/log/chef-compliance
ln -sfv /var/opt/chef-compliance/etc /etc/chef-compliance
# ln -sfv /opt/chef-compliance/sv/logrotate /opt/chef-compliance/service
# ln -sfv /opt/chef-compliance/embedded/bin/sv /opt/chef-compliance/init/logrotate

# Cleanup
cd /
rm -rf $tmpdir /tmp/install.sh /var/lib/apt/lists/* /var/cache/apt/archives/*

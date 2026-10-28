#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

#EXCLUDED-PACKAGES=(
#
#)

INCLUDED_PACKAGES=(
	tmux
	fd
	ripgrep
	# emacs
	fira-code-fonts
	libinput-devel
)

# remove excluded
# dnf5 remove --quiet -y "${EXCLUDED_PACKAGES[@]}"

# this installs a package from fedora repos
echo "*** Setting up ZeroTier repository for Fedora..."

# Import the official ZeroTier GPG key
rpm --import https://download.zerotier.com/contact@zerotier.com.gpg

# Create the repository configuration file manually and securely
cat << 'EOF' > /etc/yum.repos.d/zerotier.repo
[zerotier]
name=ZeroTier, Inc. RPM Release Repository
baseurl=https://download.zerotier.com/redhat/fc/$releasever
enabled=1
gpgcheck=1
gpgkey=https://download.zerotier.com/contact@zerotier.com.gpg
EOF

echo "*** Installing ZeroTier package..."
dnf5 install -y zerotier-one

echo "*** Installing Cisco Secure Client..."
# UT distributes the official Cisco Secure Client "predeploy" bundle via
# ServiceNow (publicly accessible, no login required). The bundle contains
# all the client RPMs plus Cisco's GPG key for signature verification.
# unzip is only needed for extraction; the CLEANUP step below removes it.
dnf5 install -y unzip
rm -rf /tmp/cisco-ut && mkdir -p /tmp/cisco-ut
curl -fSL -o /tmp/cisco-ut/bundle.zip \
    "https://ut.service-now.com/sys_attachment.do?sys_id=1b9cd86687574750fc73326e0ebb3534"
unzip -q -o /tmp/cisco-ut/bundle.zip -d /tmp/cisco-ut
tar xzf /tmp/cisco-ut/cisco-secure-client-linux64-5.1.16.194-predeploy-rpm-k9.tgz -C /tmp/cisco-ut
# Import Cisco's GPG key so the RPMs verify properly
rpm --import /tmp/cisco-ut/CiscoSystemsInc.pgp
# Install the full predeploy set: dart, posture, iseposture, nvm, vpn, vpn-cli
dnf5 install -y /tmp/cisco-ut/cisco-secure-client-*.rpm
rm -rf /tmp/cisco-ut

dnf5 install -y "${INCLUDED_PACKAGES[@]}"

# CLEANUP
# ----------------------------------------------------
dnf5 autoremove && dnf5 clean all
rm -f /var/log/dnf*.log
rm -rf /var/lib/dnf
rm -rf /var/lib/alternatives

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
systemctl enable zerotier-one.service

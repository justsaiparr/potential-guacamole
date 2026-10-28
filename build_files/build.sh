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
# Standalone RPM (not from a repo) - download it, then install locally.
# pkg_gpgcheck is disabled because the Cisco RPM is not signed with a key in our trust store.
curl -fSL -o /tmp/cisco-secure-client.rpm \
    "https://vpn.utexas.edu/CACHE/stc/3/binaries/cisco-secure-client-vpn-5.1.16.194-1.x86_64.rpm"
dnf5 install -y --setopt=pkg_gpgcheck=0 /tmp/cisco-secure-client.rpm
rm -f /tmp/cisco-secure-client.rpm

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

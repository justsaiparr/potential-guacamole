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
curl -s https://download.zerotier.com/redhat/fc/zerotier.repo -o /etc/yum.repos.d/zerotier.repo
dnf5 install -y zerotier-one
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

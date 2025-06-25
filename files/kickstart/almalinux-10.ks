url --url https://repo.almalinux.org/almalinux/10/BaseOS/x86_64/kickstart/
repo --name=BaseOS --baseurl=https://repo.almalinux.org/almalinux/10/BaseOS/x86_64/os/
repo --name=AppStream --baseurl=https://repo.almalinux.org/almalinux/10/AppStream/x86_64/os/

text
skipx
eula --agreed
firstboot --disabled

# Network
network --device=ens4 --bootproto=dhcp --ipv6=auto --activate
network --hostname=almalinux10

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# Root password
rootpw --plaintext RvHtrfTwCjTnhHrD

# System services
services --disabled="kdump" --enabled="chronyd,rsyslog,sshd"

# System timezone
timezone Europe/Amsterdam --utc

# Disk partitioning information
zerombr
clearpart --none --initlabel
autopart --nolvm --type plain --fstype xfs --nohome --noboot --noswap

# Enable SELinux
selinux --enforcing

# Package installation
%packages
@^server-product-environment
qemu-guest-agent
acpid
bind-utils
binutils
cloud-init
cloud-utils-growpart
curl
git
iotop
ipset
lsof
nano
net-tools
nmap
pciutils
rsync
tcpdump
unzip
uuid
vim-enhanced
wget
-alsa-*
-ivtv*
-iwl*firmware
patch
%end

# Post scripts
%post
dnf update -y
dnf clean all
sed -i '/^disable_root/s/1/0/ ; /^disable_root/s/true/false/ ; /^ssh_pwauth/s/0/1/ ; /^ssh_pwauth/s/false/true/' /etc/cloud/cloud.cfg
sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
%end

reboot

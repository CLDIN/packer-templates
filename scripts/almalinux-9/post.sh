#!/bin/bash
set -xe

echo "Remove DHCP leases"
find /var/lib -type f -name '*.lease' -print -delete

echo "Configuring DNS"
find /etc -maxdepth 1 -type l -name 'resolv.conf' -print -delete
echo "nameserver 2a00:f10:ff04:153::53"|tee /etc/resolv.conf
echo "nameserver 2a00:f10:ff04:253::53"|tee -a /etc/resolv.conf

echo "Enabling systemd services"
systemctl enable cloud-init cloud-config fstrim.timer qemu-guest-agent

echo "Generating GRUB configuration"
grub2-mkconfig -o /boot/grub2/grub.cfg

#[cloudinit dhcp/datasource issue](https://github.com/canonical/cloud-init/issues/5378)
echo "Workaround cloud-init issue 5378"
sed -i "s/    lease_file = dhcp.IscDhclient.parse_dhcp_server_from_lease_file/    latest_address = dhcp.IscDhclient.parse_dhcp_server_from_lease_file/" /usr/lib/python*/site-packages/cloudinit/sources/DataSourceCloudStack.py

echo "Cleaning up cloud-init"
find /var/log -type f -name 'cloud-init*.log' -print -delete
cloud-init clean -s -l

echo "Delete root password and lock account"
passwd --delete root
passwd --lock root
sed -i 's|^ *PermitRootLogin .*|PermitRootLogin yes|g' /etc/ssh/sshd_config
sed -i 's|^ *PasswordAuthentication .*|PasswordAuthentication no|g' /etc/ssh/sshd_config

unset HISTFILE

sync

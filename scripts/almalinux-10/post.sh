#!/bin/bash
set -xe

echo "Remove DHCP leases"
find /var/lib -type f -name '*.lease' -print -delete

#packer sees ens4, cloudstack ens3. So we need to prepare ens3.
echo "Configuring network interface"
nmcli con add connection.interface-name ens3 type ethernet connection.id ens3
nmcli connection modify ens3 autoconnect yes

echo "Set NetworkManager global ipv6 address generation mode to eui64"
echo "[connection]" | tee -a /etc/NetworkManager/NetworkManager.conf
echo "ipv6.addr-gen-mode=0" | tee -a /etc/NetworkManager/NetworkManager.conf

echo "Configuring DNS"
find /etc -maxdepth 1 -type l -name 'resolv.conf' -print -delete
echo "nameserver 2a00:f10:ff04:153::53"|tee /etc/resolv.conf
echo "nameserver 2a00:f10:ff04:253::53"|tee -a /etc/resolv.conf

echo "Enabling systemd services"
systemctl enable cloud-init cloud-config fstrim.timer qemu-guest-agent

#[cloudinit dhcp/datasource issue](https://github.com/canonical/cloud-init/issues/5378)
echo "Workaround cloud-init issue 5378"
sed -i "s/    lease_file = dhcp.IscDhclient.parse_dhcp_server_from_lease_file/    latest_address = dhcp.IscDhclient.parse_dhcp_server_from_lease_file/" /usr/lib/python*/site-packages/cloudinit/sources/DataSourceCloudStack.py

# Fix Cloudstack datasource with patch file
patch -u /usr/lib/python*/site-packages/cloudinit/sources/DataSourceCloudStack.py -i /tmp/DataSourceCloudStack.patch
patch -u /usr/lib/python*/site-packages/cloudinit/net/dhcp.py -i /tmp/net_dhcp.patch

echo "Cleaning up cloud-init"
find /var/log -type f -name 'cloud-init*.log' -print -delete
cloud-init clean -s -l

echo "Delete root password and lock account"
passwd --delete root
passwd --lock root
sed -i 's|^ *PermitRootLogin .*|PermitRootLogin yes|g' /etc/ssh/sshd_config
sed -i 's|^ *PasswordAuthentication .*|PasswordAuthentication no|g' /etc/ssh/sshd_config

echo "Deleting existing ssh host keys"
rm -f /etc/ssh/ssh_host*

yum -y remove patch

unset HISTFILE

sync

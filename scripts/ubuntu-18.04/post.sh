#!/bin/bash
echo "Removing uneeded packages"
apt-get -y autoremove
apt-get -y clean

echo "Disabling apt timers"
systemctl disable apt-daily.timer apt-daily-upgrade.timer

echo "cleaning up dhcp leases"
find /var/lib/dhcp -type f -delete

echo "Remove SSH host keys"
find /etc/ssh -type f -name 'ssh_host*key*' -delete

echo "cleaning up udev rules"
rm -f /etc/udev/rules.d/70-persistent-net.rules

echo "Configuring network interface"
sed -i 's|ens[0-9]|ens3|g' /etc/netplan/01-netcfg.yaml

echo "Configuring DNS"
echo "nameserver 2a00:f10:ff04:153::53"|tee -a /etc/resolvconf/resolv.conf.d/head
echo "nameserver 2a00:f10:ff04:253::53"|tee -a /etc/resolvconf/resolv.conf.d/head

echo "cleaning up log files"
if [ -f /var/log/audit/audit.log ]; then cat /dev/null > /var/log/audit/audit.log; fi
cat /dev/null > /var/log/wtmp 2>/dev/null
logrotate -f /etc/logrotate.conf 2>/dev/null
rm -f /var/log/*-* /var/log/*.gz 2>/dev/null
rm -f /var/log/upstart/*.log /var/log/upstart/*.log.*.gz

echo "Cleaning up cloud-init"
cloud-init clean --logs

unset HISTFILE

sync
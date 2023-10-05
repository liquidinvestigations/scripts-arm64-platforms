sudo bash <<EOF
set -e
sync

# install packages
apt-get update -y
apt-get install -y tmux wget vim curl git python3-venv python3-pip unzip nohang mdadm ntp
timedatectl set-ntp true


# install docker
if ! docker --version; then
        curl https://get.docker.com | bash
        adduser pi docker
fi

# delete swapfile
echo "CONF_SWAPSIZE=0" > /etc/dphys-swapfile
dphys-swapfile swapoff
dphys-swapfile uninstall
update-rc.d dphys-swapfile remove

# configure read-only reboot options
# https://webcache.googleusercontent.com/search?q=cache:https://medium.com/swlh/make-your-raspberry-pi-file-system-read-only-raspbian-buster-c558694de79

apt-get remove -y --purge triggerhappy logrotate dphys-swapfile
apt-get autoremove --purge -y
echo "console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait fastboot noswap ro" > /boot/cmdline.txt
apt-get install -y busybox-syslogd
apt-get remove --purge -y rsyslog

# set up tmpfs disks
cat >/etc/fstab <<EOFSTAB

proc            /proc           proc    defaults          0       0
/dev/mmcblk0p1  /boot           vfat    defaults,ro          0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime,ro  0       1

tmpfs        /tmp            tmpfs   defaults,noatime,nosuid,nodev,noexec,mode=0777,size=128M         0       0
tmpfs        /var/log        tmpfs   defaults,noatime,nosuid,nodev,noexec,mode=0777,size=64M         0       0
tmpfs        /var/tmp        tmpfs   defaults,noatime,nosuid,nodev,noexec,mode=0777,size=64M         0       0
tmpfs        /var/lib/dhcp        tmpfs   defaults,noatime,nosuid,nodev,noexec,mode=0777,size=64M         0       0
tmpfs        /var/lib/dhcpcd5        tmpfs   defaults,noatime,nosuid,nodev,noexec,mode=0777,size=64M         0       0
tmpfs        /var/spool        tmpfs   defaults,noatime,nosuid,nodev,noexec,mode=0777,size=64M         0       0

EOFSTAB

# change to temps
rm -rf /var/lib/dhcp /var/lib/dhcpcd5 /var/spool /etc/resolv.conf
mkdir -p /var/lib/dhcp /var/lib/dhcpcd5 /var/spool
chmod a+rwx mkdir -p /var/lib/dhcp /var/lib/dhcpcd5 /var/spool

touch /tmp/dhcpcd.resolv.conf
ln -s /tmp/dhcpcd.resolv.conf /etc/resolv.conf

rm /var/lib/systemd/random-seed
ln -s /tmp/random-seed /var/lib/systemd/random-seed
echo 'ExecStartPre=/bin/echo "" >/tmp/random-seed' >> /lib/systemd/system/systemd-random-seed.service

# override bash prompt

cat >>/etc/bash.bashrc <<EOBASHRC

alias rootfs-ro='sudo mount -o remount,ro / ; sudo mount -o remount,ro /boot'
alias rootfs-rw='sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot'

EOBASHRC

sync
echo "plz reboot"
EOF

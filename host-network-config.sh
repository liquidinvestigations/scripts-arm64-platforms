set -ex
IF=$1
if ! [ "$IF" ]; then
        echo "ERROR: no INTERFACE argument given"
        echo "usage: $0 INTERFACE"
        exit 1
fi
SUBNET=192.168.69



ifdown $IF
ifup $IF
iptables -t nat -s $SUBNET.0/24 -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -j ACCEPT
cat >/etc/network/interfaces.d/$IF <<EOF2
auto $IF
iface $IF inet static
    address $SUBNET.100
    netmask 255.255.255.0
    broadcast $SUBNET.255
EOF2
systemctl restart networking
systemctl restart isc-dhcp-server
# ip route delete default via $SUBNET.1 dev $IF onlink

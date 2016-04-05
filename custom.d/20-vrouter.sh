#
# Install Contrail vrouter
#

. ./functions.sh

if [ "$BUILD_KERNEL" = false ]; then
    chroot_exec apt-get install -qq -y linux-headers-${KERNEL}
fi

chroot_exec apt-get install -qq -y bridge-utils vim ethtool python-pip
chroot_exec apt-get install -qq -y contrail-vrouter-agent || true

wget -O $R/lib/modules/$(ls $R/lib/modules|head -1)/vrouter.ko http://apt.tcpcloud.eu/tmp/vrouter.ko
#chroot_exec depmod -a

cat << EOF >> $R/etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

/sbin/ip r a default via $VROUTER_GATEWAY

exit 0
EOF

cat << EOF >> $R/etc/network/interfaces.d/eth0.cfg
auto eth0
iface eth0 inet static
    address 0.0.0.0
    up link set eth0 up
    down link set eth0 down
EOF

cat << EOF >> $R/etc/network/interfaces.d/vhost0.cfg
auto vhost0
iface vhost0 inet static
    pre-up depmod -a
    pre-up modprobe vrouter
    pre-up ip link add name vhost0 type vhost
    pre-up ip link set vhost0 address \$(cat /sys/class/net/eth0/address)
    pre-up vif --add eth0 --mac \$(cat /sys/class/net/eth0/address) --vrf 0 --vhost-phys --type physical
    pre-up vif --add vhost0 --mac \$(cat /sys/class/net/eth0/address) --vrf 0 --type vhost --xconnect eth0
    address $VROUTER_ADDRESS
    netmask 255.255.255.0
    dns-nameservers 8.8.8.8
    up ip addr flush eth0
    up ip route add default via $VROUTER_GATEWAY
    post-down vif --list | awk '/^vif.*OS: vhost0/ {split(\$1, arr, "\\/"); print arr[2];}' | xargs vif --delete
    post-down vif --list | awk '/^vif.*OS: eth0/ {split(\$1, arr, "\\/"); print arr[2];}' | xargs vif --delete
    post-down ip link delete vhost0
EOF

cat << EOF >> $R/etc/contrail/contrail-vrouter-agent.conf
[CONTROL-NODE]

[VIRTUAL-HOST-INTERFACE]
name=vhost0
ip=$VROUTER_ADDRESS
physical_interface=eth0
gateway=$VROUTER_GATEWAY

[DISCOVERY]
server=10.0.170.70

max_control_nodes=2

[NETWORKS]
control_network_ip=$VROUTER_ADDRESS

[HYPERVISOR]
type=kvm
EOF

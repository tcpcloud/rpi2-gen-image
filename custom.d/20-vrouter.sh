#
# Install Contrail vrouter
#

. ./functions.sh

if [ "$BUILD_KERNEL" = false ]; then
    chroot_exec apt-get install -qq -y linux-headers-${KERNEL}
fi

chroot_exec apt-get install -qq -y bridge-utils ethtool python-pip
chroot_exec apt-get install -qq -y contrail-vrouter-agent || true

wget -O $R/lib/modules/${KERNEL}/vrouter.ko http://apt.tcpcloud.eu/tmp/vrouter.ko
#chroot_exec depmod -a

cat << EOF >> $R/etc/network/interfaces.d/vhost0.conf
auto vhost0
iface vhost0 inet static
    pre-up modprobe vrouter
    pre-up ip link add name vhost0 type vhost
    pre-up ip link set vhost0 address \$(cat /sys/class/net/eth0/address)
    pre-up vif --add eth0 --mac \$(cat /sys/class/net/eth0/address) --vrf 0 --vhost-phys --type physical
    pre-up vif --add vhost0 --mac \$(cat /sys/class/net/eth0/address) --vrf 0 --type vhost --xconnect eth0
    address $VROUTER_ADDRESS
    netmask 255.255.255.0
    dns-nameservers 8.8.8.8
    up ip addr flush eth0
    up ip route add default via 176.16.1.1
    post-down vif --list | awk '/^vif.*OS: vhost0/ {split(\$1, arr, "\\/"); print arr[2];}' | xargs vif --delete
    post-down vif --list | awk '/^vif.*OS: eth0/ {split(\$1, arr, "\\/"); print arr[2];}' | xargs vif --delete
    post-down ip link delete vhost0
EOF

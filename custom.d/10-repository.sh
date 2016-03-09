#
# Setup tcpcloud repository
#

. ./functions.sh

chroot_exec "apt-get install -qq -y wget"
echo "deb http://apt.tcpcloud.eu/raspbian/ jessie extra oc222" > $R/etc/apt/sources.list.d/tcpcloud.list
chroot_exec "wget http://apt.tcpcloud.eu/public.gpg"
chroot_exec "apt-key add public.gpg"
chroot_exec "rm -f public.gpg"
chroot_exec "apt-get update"

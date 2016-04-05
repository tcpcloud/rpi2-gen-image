#
# Install docker and Kubernetes
#

. ./functions.sh

chroot_exec wget https://downloads.hypriot.com/docker-hypriot_1.9.1-1_armhf.deb && \
    chroot_exec dpkg -i docker-hypriot_1.9.1-1_armhf.deb

wget -O $R/usr/local/bin/kubelet http://apt.tcpcloud.eu/tmp/k8s_binaries_arm/v1.1.1/kubelet
wget -O $R/usr/local/bin/kube-proxy http://apt.tcpcloud.eu/tmp/k8s_binaries_arm/v1.1.1/kube-proxy

chmod +x $R/usr/local/bin/kubelet
chmod +x $R/usr/local/bin/kube-proxy

chroot_exec pip install opencontrail-kubelet
chroot_exec mkdir -p /usr/libexec/kubernetes/kubelet-plugins/net/exec/opencontrail/
chroot_exec ln -s /usr/local/bin/opencontrail-kubelet-plugin /usr/libexec/kubernetes/kubelet-plugins/net/exec/opencontrail/opencontrail
chroot_exec ln -s /lib/ld-linux-armhf.so.3 /lib/ld-linux.so.3

chroot_exec mkdir -p /etc/kubernetes/certs
chroot_exec touch /var/log/kube-proxy.log
chroot_exec touch /var/log/kubelet.log

# /usr/bin/docker daemon -H fd:// --storage-driver=overlay -D
#chroot_exec "service docker start"
#chroot_exec "docker pull tcpcloud/pause_armhf:2.0"
#chroot_exec "docker tag tcpcloud/pause_armhf:2.0 gcr.io/google_containers/pause:2.0"

for service in kubelet kube-proxy vrouter-agent; do
    install -o root -g root -m 644 files/kubernetes/${service}.service $R/etc/systemd/system/${service}.service
    chroot_exec systemctl enable ${service}.service
done

cat << EOF >> $R/etc/default/kubelet
DAEMON_ARGS="--api-servers=$K8S_API_SERVER --hostname-override=$HOSTNAME --kubeconfig=/etc/kubernetes/kubelet.kubeconfig --config=/etc/kubernetes/manifests --allow-privileged=True --cluster_dns=$K8S_CLUSTER_DNS --cluster_domain=$K8S_CLUSTER_DOMAIN --v=5 --network-plugin=opencontrail --file-check-frequency=5s"
EOF

cat << EOF >> $R/etc/default/kube-proxy
DAEMON_ARGS="--logtostderr=true --v=2 --kubeconfig=/etc/kubernetes/proxy.kubeconfig --master=$K8S_API_SERVER"
EOF

cat << EOF >> $R/etc/default/vrouter-agent
DAEMON_ARGS=" --config_file=/etc/contrail/contrail-vrouter-agent.conf --DEFAULT.log_file=/var/log/contrail/vrouter.log"
EOF

cat << EOF >> $R/etc/kubernetes/proxy.kubeconfig
apiVersion: v1
kind: Config
current-context: proxy-to-cluster.local
preferences: {}
contexts:
- context:
    cluster: cluster.local
    user: proxy
  name: proxy-to-cluster.local
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/certs/ca.crt
  name: cluster.local
users:
- name: proxy
  user:
    token:
EOF

cat << EOF >> $R/etc/kubernetes/kubelet.kubeconfig
apiVersion: v1
kind: Config
current-context: kubelet-to-cluster.local
preferences: {}
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/certs/ca.crt
  name: cluster.local
contexts:
- context:
    cluster: cluster.local
    user: kubelet
  name: kubelet-to-cluster.local
users:
- name: kubelet
  user:
    token:
EOF
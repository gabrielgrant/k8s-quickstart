#! /bin/bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
# Install docker if you don't have it already.
apt-get install -y docker.io
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
kubeadm init
kubectl taint nodes --all dedicated-

# install networking
kubectl apply -f https://git.io/weave-kube

echo "Waiting for networking to come up"
start_time=$(date +%s)
while true; do
  kube_dns_running="$(kubectl get pods --all-namespaces | grep kube-dns | grep Running)"
  if [[ -n "$kube_dns_running" ]]; then
    break;
  fi
  printf "."
  sleep 1
  runtime=$(($(date +%s)-$start_time))
  if [ $runtime -ge 120 ]; then
    (>&2 echo "Timed out waiting for kube-dns (120s)")
    exit 1;
  fi
done

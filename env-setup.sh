#!/bin/bash

K3D="/usr/local/bin/k3d"
IP_ADDR=$(ip route show | grep '^[0-9]' | awk '{print $9}')

function install_epinio_with_deps() {
    # cert-manager
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager  \
        --set installCRDs=true --version v1.13.2 \
        --set extraArgs={--enable-certificate-owner-ref=true} \
        --create-namespace
    sleep 10

    # epinio
    helm repo add epinio https://epinio.github.io/helm-charts
    helm repo update
    helm upgrade --install epinio epinio/epinio --namespace epinio --create-namespace \
        --set global.domain="${IP_ADDR}".sslip.io
}

if [ ! -f "${K3D}" ]; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

k3d cluster create epinio -p '80:80@loadbalancer' -p '443:443@loadbalancer'
until kubectl get svc -n kube-system | grep -q "^traefik"; do
    echo "Checking k3d lb status..."
    sleep 5
done

install_epinio_with_deps

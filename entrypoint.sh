#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail



get_cluster_config(){
cat > config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
}


get_meshconfig(){
mkdir $HOME/.meshery
cat > ~/.meshery/config.yaml <<EOF
contexts:
  local:
    endpoint: http://meshery.local
    token: Default
    platform: kubernetes
    adapters:
    - meshery-istio
    - meshery-linkerd
    - meshery-consul
    - meshery-nsm
    - meshery-kuma
    - meshery-cpx
    - meshery-osm
    - meshery-traefik-mesh
    - meshery-nginx-sm
    channel: stable
    version: latest
current-context: local
tokens:
- name: Default
  location: auth.json
EOF
}

expose_meshery(){
cat > ~/.meshery/ingress.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: meshery-ingress
  labels:
    name: meshery-ingress
spec:
  rules:
  - host: meshery.local
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: meshery
            port: 
              number: 9081
EOF
kubectl apply -n meshery -f ~/.meshery/ingress.yaml 
}

install_kubectl(){
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
}


setup_k8s() {
	GO111MODULE="on" go get sigs.k8s.io/kind@v0.11.1
	get_cluster_config
	echo "::debug::Installing Kubectl..."
	install_kubectl
	echo "::debug::Done..."
	echo "::debug::Creating Kubernetes cluster"
	kind create cluster  --name meshery-ci --config config.yaml 
	echo "::debug::Created Kubernetes cluster"
}

install_helm(){ 
	# Because i like living on the edge
	echo "::debug::Installing Helm"
	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
	echo "::debug::Installed Helm"
}


deploy_meshery(){
  echo "::debug::installing mesheryctl"
  curl -L https://github.com/meshery/meshery/releases/download/v0.5.67/mesheryctl_0.5.67_Linux_x86_64.zip -o mesheryctl.zip
  unzip -n mesheryctl.zip 
  mv mesheryctl /usr/local/bin/mesheryctl
  get_meshconfig
  export KUBECONFIG=$(kind get kubeconfig --name=meshery)
  echo "::debug::Installed mesheryctl"
  kubectl create namespace meshery
  echo "::debug::Deploying Meshery....."
  helm install meshery --namespace meshery --repo https://github.com/meshery/meshery/tree/master/install/kubernetes/helm/meshery
  expose_meshery  
  echo "127.0.0.1 meshery.local" >> /etc/hosts
  echo "::debug::Deployed Meshery....."
}


main(){
 install_helm
 setup_k8s
 deploy_meshery
}

main
#!/usr/bin/env bash

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
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
}


setup_k8s() {
	curl https://golang.org/dl/go1.17.2.linux-amd64.tar.gz -o go.tar.gz 
	rm -rf /usr/local/go && tar -C /usr/local -xzf go.tar.gz
	export PATH=$PATH:/usr/local/go/bin
	source $HOME/.profile
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
	curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
	echo "::debug::Installed Helm"
}



deploy_meshery(){
  echo "::debug::installing mesheryctl"
  curl https://github.com/meshery/meshery/releases/download/v0.5.67/mesheryctl_0.5.67_Linux_x86_64.zip mesheryctl.zip
  unzip mesheryctl.zip 
  mv mesheryctl /usr/local/bin/mesheryctl
  get_meshconfig
  echo "::debug::Installed mesheryctl"
  git clone https://github.com/layer5io/meshery.git; cd meshery
  kubectl create namespace meshery
  echo "::debug::Deploying Meshery....."
  helm install meshery --namespace meshery install/kubernetes/helm/meshery
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
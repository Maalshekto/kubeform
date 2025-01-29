#!/bin/bash
# Install Jenkins

# TODO: Install Jenkins using Helm
# helm repo add jenkins https://charts.jenkins.io 
# helm repo update
# helm install jenkins jenkins/jenkins --namespace jenkins --create-namespace --set prefix=/jenkins --set controller.service.type=NodePort --set controller.service.nodePort=30080 --set persistence.storageClass=local-storage

# Install Jenkins using Kubernetes manifests

# Clone the kubernetes-jenkins repository
git clone https://github.com/scriptcamp/kubernetes-jenkins /home/ubuntu/kubernetes-jenkins
cd /home/ubuntu/kubernetes-jenkins

# Apply the Kubernetes manifests
kubectl apply -f namespace.yaml --validate=false
kubectl apply -f serviceAccount.yaml --validate=false

# Update the volume.yaml file to use the correct node name
sed -i "s|- worker-node01|- $(kubectl get nodes -o custom-columns=NAME:.metadata.name --no-headers | grep 1)|" volume.yaml
# Apply the updated volume.yaml file    
kubectl apply -f volume.yaml --validate=false

# Update the deployment.yaml file to add the JENKINS_OPTS environment variable with the correct prefix
sed -i '/cpu: "500m"/a \          env:\n            - name: JENKINS_OPTS\n              value: "--prefix=/jenkins"' deployment.yaml
# Update the deployment.yaml file to use the correct path in liveness and readiness probes
sed -i 's|path: "/login"|path: "/jenkins/login"|g' deployment.yaml
# Apply the updated deployment.yaml file
kubectl apply -f deployment.yaml --validate=false

# Update the service.yaml file to use the correct service type : nodePort
sed -i 's|nodePort: 32000|nodePort: 30080\n  type: NodePort|g' service.yaml
# Apply the updated service.yaml file
kubectl apply -f service.yaml --validate=false
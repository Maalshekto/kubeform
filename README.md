# Terraform Kubernetes Cluster Setup

## Description

This project automates the deployment of a Kubernetes development/lab cluster on AWS using EC2 instances (not EKS). It provisions the necessary AWS infrastructure, including VPC, subnets, security groups, and EC2 instances for the bastion host, Kubernetes control-plane, and worker nodes. The setup scripts install and configure Kubernetes components, Docker, and other essential tools. Additionally, it generates an SSH configuration file for seamless access to the cluster nodes via the bastion host.

## Prerequisites

Before you begin, ensure you have met the following requirements:

- **Operating System**: Linux, macOS, or Windows (with WSL for Windows users).
- **Terraform**: Installed on your local machine. [Download Terraform](https://www.terraform.io/downloads.html)
- **AWS Account**: You must have an AWS account with the necessary permissions to create resources.
- **AWS CLI**: Installed and configured with your AWS credentials. [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **SSH Key Pair**: Have an SSH key pair generated. If you don't have one, generate it using:
  ```bash
  ssh-keygen -t ed25519 -C "your_email@example.com"
  ```
-   **Public IP Address**: Your current public IP address, to be used for SSH access to the bastion host. Be careful if you are using VPN, only the provided public IP address will be able to reach bastion. 

## Setup Instructions

### 1. Clone the Repository

Clone this repository to your local machine:


```bash
git clone https://github.com/Maalshekto/kubeform.git
cd kubeform
```
### 2. Install Terraform

If Terraform is not already installed, follow these steps:

-   **Linux/macOS**:
    
```bash
wget https://releases.hashicorp.com/terraform/<version>/terraform_<version>_linux_amd64.zip
unzip terraform_<version>_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version
```
-   **Windows**:
    
    Download the Terraform binary from the Terraform website and add it to your PATH.
    

### 3. Configure AWS CLI

Ensure that your AWS CLI is configured with the necessary credentials:
```bash
aws configure
```
Provide your AWS Access Key ID, Secret Access Key, region, and output format when prompted.

### 4. Retrieve Your Public IP Address

To securely SSH into the bastion host, you need your current public IP address. Run the following command:

-   **Linux/macOS**:
```bash
curl -s ifconfig.me` 
```
    
-   **Windows PowerShell**:
```bash
(Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
```    

Note down your public IP address.

### 5. Configure Terraform Variables

create a `terraform.tfvars` file to specify your variable values. Here's an example template:

```hcl
aws_region = "eu-west-3"

vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

bastion_ami = "ami-08b426ca1360eb488" # Replace with appropriate AMI for your region
k8s_ami = "ami-08b426ca1360eb488" # Replace with appropriate AMI for your region

bastion_ingress_user_public_ip = "YOUR_PUBLIC_IP/32" # Replace with your public IP

instance_type_bastion = "t3.small"
instance_type_master = "t3.medium"
instance_type_worker = "t3.medium"
public_key_path = "~/.ssh/id_ed25519.pub" # Path to your SSH public key
num_workers = 2 # Can be modify but remember : "with great power comes great responsibility"

# Common Tags for resources
cluster_name = "JMA" # Change this to a unique name for your cluster - Here a trigram based on owner name
owner = "Jean MARTIN" # Change this to your name
deployed_by = "Jean MARTIN" # Change this to your name
project = "my-project" # Change this to the name of your project
environment = "dev" # Change this to the environment name
```

Replace `YOUR_PUBLIC_IP` with the IP address you retrieved earlier.

Replace cluster_name with what you want eventually a trigram based on your name 
Check with your team that you have unique cluster_name.

owner/deployed_by should be your name as you are both deployer and owner of the kubernetes cluster.

### 6. Initialize Terraform

Initialize the Terraform project to download the necessary providers and modules:
```bash
terraform init
``` 
### 7. Plan the Terraform Deployment

Generate an execution plan to see the resources that will be created:


```bash
terraform plan
``` 

Review the plan to ensure that it matches your expectations.

### 8. Apply the Terraform Configuration

Apply the Terraform configuration to provision the infrastructure:


```bash
terraform apply
``` 
Type `yes` when prompted to confirm the deployment.

Terraform will create the VPC, subnets, security groups, key pair, and EC2 instances for the bastion host, Kubernetes control-plane, and worker nodes. It will also generate an SSH configuration file.

## Configuration and Installation

After the infrastructure is provisioned, the EC2 instances will execute the user data scripts to install and configure the necessary software:

-   **Bastion Host (`bastion.sh`)**:
    
    -   Adds your SSH public key for secure access.
    -   Updates the system packages.
    -   Installs `htop`, Docker, and Docker Compose.
-   **Kubernetes Master Node (`k8s-master.sh`)**:
    
    -   Adds your SSH public key.
    -   Disables swap.
    -   Installs Docker and configures containerd.
    -   Enables IP forwarding and configures necessary kernel modules.
    -   Installs Kubernetes components (`kubelet`, `kubeadm`, `kubectl`).
    -   Initializes the Kubernetes cluster.
    -   Installs Calico for network management.
    -   Generates a join command for worker nodes.
    -   Installs Helm and deploys Ingress Nginx using Helm.
-   **Kubernetes Worker Nodes (`k8s-worker.sh`)**:
    
    -   Adds your SSH public key.
    -   Disables swap.
    -   Installs Docker and configures containerd.
    -   Enables IP forwarding and configures necessary kernel modules.
    -   Installs Kubernetes components (`kubelet`, `kubeadm`, `kubectl`).
    -   Joins the Kubernetes cluster using the join command provided by the master node.
    -   Restarts Docker and kubelet to ensure proper operation.

## Accessing the Machines

### SSH Configuration

A custom SSH configuration file (`terraform_ssh_config`) is generated to simplify access to the bastion host, control-plane, and worker nodes. The configuration uses the bastion host as a proxy to access the internal machines.

1.  **Locate the SSH Config File**:
    
    The file is saved at `~/.ssh/terraform_ssh_config`.
    
2.  **Include it in Your SSH Configuration**:
    
    Add the following line to your main SSH config (`~/.ssh/config`):
	```bash
	include ~/.ssh/terraform_ssh_config
	```
    
3.  **Connect to the Bastion Host**:

	```bash 
	ssh bastion
	```
4.  **Connect to the Control-plane Node**:
	```bash 
    ssh aws-cp
	```
5.  **Connect to a Worker Node**:
    
    Replace `<worker-number>` with the appropriate number (e.g., `aws-wk1`, `aws-wk2`):
	```
	ssh aws-wk1
	```
### Verify SSH Access

Ensure that you can SSH into the bastion host and from there access the control-plane and worker nodes.

## Verifying the Cluster

Once the Terraform deployment is complete and the Kubernetes cluster is initialized, perform the following steps to ensure everything is functioning correctly:

1.  **SSH into the Control-plane Node**:
    
	```bash 
    ssh aws-cp
	```
    
2.  **Check Kubernetes Nodes**:
    
 	```bash 
    kubectl get nodes
    ```
     
    You should see the control-plane and worker nodes listed with the status `Ready`.
    The cluster should be ready around 5 minutes after `terraform apply`.
    If some nodes are not ready or even not present, wait several minutes for them to be present & ready.
        
## Troubleshooting

If you encounter issues during the deployment or configuration:

-   **Check Terraform Logs**: Review the output from Terraform commands for any errors.
-   **Inspect EC2 Instance Logs**: SSH into the bastion host and other nodes to check logs for any setup script failures.
-   **Verify AWS Resources**: Use the AWS Management Console or AWS CLI to verify that all resources have been created as expected.
-   **Review Kubernetes Logs**: On the control-plane node, use `kubectl logs` to inspect logs from Kubernetes components.
-   **Check Network Configurations**: Ensure that security groups and network ACLs are correctly configured to allow necessary traffic.

## Next Steps

-   **Configure Ingress Resources**: Define ingress rules to manage traffic routing to your Kubernetes services.
-   **Set Up Monitoring and Logging**: Implement monitoring tools like Prometheus and Grafana, and logging solutions to track cluster performance.
-   **Implement Security Best Practices**: Secure your Kubernetes cluster by implementing RBAC, network policies, and regularly updating your software.

## License

This project is licensed under the MIT License.

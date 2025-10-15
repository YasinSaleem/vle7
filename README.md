# VLE7 - Complete Blue-Green Deployment Pipeline

A fully automated end-to-end CI/CD pipeline implementing blue-green deployment strategy using Jenkins and Kubernetes on AWS, optimized for t3.small instances.

## 🎯 Overview

This project provides a **complete, automated setup** for a production-ready blue-green deployment pipeline with:

- 🏗️ **Automated AWS Infrastructure** provisioning with Terraform (t3.small optimized)
- ⚙️ **Jenkins CI/CD** with automatic configuration
- ☸️ **Kubernetes** orchestration (remote cluster support)
- 🔵🟢 **Blue-Green Deployment** with traffic switching
- 🚦 **Manual approval gates** for production safety
- 🔄 **Automatic rollback** on failures
- 💾 **Memory optimized** - no Docker on Jenkins instance

## 🏛️ Architecture

```
GitHub Push → Jenkins Pipeline → Remote K8s → Blue/Green Deploy → Traffic Switch
     ↓              ↓               ↓              ↓                ↓
  Webhook    →  Auto Trigger  →  Cluster API  →  nginx Pods   →  Service Update
```

**Deployment Flow:**
1. **Blue Environment**: Current production (stable)
2. **Green Environment**: New deployment (testing)
3. **Traffic Switch**: Seamless cutover with zero downtime
4. **Rollback**: Automatic revert on failure

## 🚀 One-Command Setup

### Prerequisites

Ensure you have:
- ✅ **AWS Account** with appropriate permissions
- ✅ **AWS CLI** configured (`aws configure`)
- ✅ **Terraform** installed (v1.0+)
- ✅ **Ansible** installed (v2.9+)
- ✅ **SSH key pair** in AWS named `yasinkey` (`.pem` file in `~/.ssh/`)

### Complete Automated Setup

```bash
# 1. Clone the repository
git clone https://github.com/YasinSaleem/vle7.git
cd vle7

# 2. Ensure SSH key permissions
chmod 400 ~/.ssh/yasinkey.pem

# 3. Run the complete setup (everything automated!)
./init.sh
```

That's it! The script will:
1. ✅ Check all prerequisites and dependencies
2. 🏗️ Deploy AWS infrastructure with Terraform (EC2, Security Groups, IAM)
3. 📋 Generate Ansible inventory from Terraform outputs
4. ⏳ Wait for instance to be fully ready and accessible
5. ⚙️ Configure Jenkins, Docker, kubectl, and Minikube with Ansible
6. 🚀 Automatically create Jenkins pipeline job
7. 🔍 Verify the complete setup
8. 📋 Display access credentials and instructions

## 📁 Project Structure

```
vle7/
├── 🚀 init.sh                    # One-command complete setup
├── 📋 Jenkinsfile                # Complete blue-green pipeline
├── 📖 README.md                  # This file
├── 
├── 🏗️ infra/
│   ├── terraform/               # AWS infrastructure
│   │   ├── main.tf             # Complete EC2, security groups, IAM
│   │   ├── variables.tf        # Configurable parameters
│   │   ├── outputs.tf          # Instance details, URLs
│   │   └── inventory.tpl       # Ansible inventory template
│   └── ansible/                # Configuration automation
│       ├── inventory.ini       # Auto-generated from Terraform
│       ├── jenkins_setup.yml   # Complete Jenkins setup
│       └── group_vars/
│           └── all.yml         # Global configuration
├── 
└── 📦 app/                      # Application & Kubernetes
    ├── Dockerfile              # Node.js application container
    ├── server.js               # Sample application
    ├── package.json            # Dependencies
    └── k8s/                    # Kubernetes manifests
        ├── deployment-blue.yaml    # Blue environment
        ├── deployment-green.yaml   # Green environment
        ├── service.yaml           # LoadBalancer service
        └── kustomization.yaml     # Kustomize configuration
```

## 🔵🟢 Blue-Green Deployment Process

### Automated Pipeline Stages

1. **🚀 Initialize**
   - Set environment variables
   - Display deployment parameters

2. **📥 Checkout**
   - Code already available (Jenkins auto-checkout)

3. **� Prepare Application** (Optional)
   - Prepare application for deployment
   - Update build metadata
   - Skip with `SKIP_DOCKER_BUILD` parameter

4. **☸️ Deploy Application**
   - Deploy to chosen color environment
   - Apply Kubernetes manifests
   - Verify deployment creation

5. **⏳ Wait for Rollout**
   - Wait for pods to be ready
   - Timeout after 5 minutes
   - Display pod status and logs

6. **🏥 Health Check**
   - Verify pods are running
   - Check application endpoints
   - Ensure minimum replica count

7. **🚦 Traffic Switch Approval**
   - **Manual approval gate**
   - Display deployment summary
   - 10-minute timeout for decision

8. **🔄 Switch Traffic**
   - Update service selector
   - Route traffic to new environment
   - Verify endpoint changes

9. **🔍 Post-Switch Verification**
   - Confirm traffic flow
   - Validate service endpoints
   - Check pod connectivity

10. **🧹 Cleanup** (Optional)
    - Remove old deployment
    - Free cluster resources
    - Keep both for safety (default)

## 🎮 Usage Guide

### 🌐 Access Your Environment

After setup completion:

```bash
# Jenkins Dashboard
# URL displayed in setup output
# Username: admin
# Password: shown in Ansible output

# SSH to Instance
ssh -i ~/.ssh/yasinkey.pem ec2-user@<instance-ip>

# Access Application (from instance)
kubectl port-forward service/vle7-app-service 8080:80
# Then visit: http://localhost:8080

# Or use Minikube
minikube service vle7-app-service --url
```

### 🚀 Trigger Deployments

#### 1. Via GitHub Webhook (Automated)
- Add webhook: `http://<instance-ip>:8080/github-webhook/`
- Push to `main` branch
- Pipeline triggers automatically

#### 2. Via Jenkins UI (Manual)  
- Access Jenkins dashboard
- Open `vle7-app-pipeline` job
- Click "Build with Parameters"
- Choose:
  - **Deployment Color**: Blue or Green
  - **Skip Docker Build**: true/false

### 📊 Monitor Deployments

```bash
# SSH to instance
ssh -i ~/.ssh/yasinkey.pem ec2-user@<instance-ip>

# Check Kubernetes status
kubectl get all
kubectl get deployments -l app=vle7-app
kubectl get pods -l app=vle7-app

# Check service routing
kubectl describe service vle7-app-service

# View application logs
kubectl logs -l app=vle7-app,version=blue
kubectl logs -l app=vle7-app,version=green

# Check which environment is active
kubectl get service vle7-app-service -o jsonpath='{.spec.selector}'
```

## 🛠️ Management & Operations

### 💰 Cost Management

```bash
# Get instance ID
cd infra/terraform
INSTANCE_ID=$(terraform output -raw instance_id)

# Stop instance (save money)
aws ec2 stop-instances --instance-ids $INSTANCE_ID

# Start instance (resume work)
aws ec2 start-instances --instance-ids $INSTANCE_ID
# Note: IP will change, update inventory and webhook

# Destroy everything
terraform destroy
```

### 🔧 Maintenance Commands

```bash
# Restart services
sudo systemctl restart jenkins
sudo systemctl restart docker

# Reset Minikube
minikube delete
minikube start --driver=docker --memory=1024

# View logs
sudo journalctl -u jenkins -f
kubectl logs -f deployment/vle7-app-blue
```

### 🚨 Troubleshooting

#### Common Issues

1. **🔴 Pods in CrashLoopBackOff**
   ```bash
   kubectl describe pod <pod-name>
   kubectl logs <pod-name> --previous
   # Health checks may be commented out in YAML files
   ```

2. **🌐 Service Not Accessible**
   ```bash
   kubectl get service vle7-app-service
   minikube service vle7-app-service --url
   # Check security group allows traffic
   ```

3. **🔧 Jenkins Not Accessible**
   ```bash
   # Check Jenkins status
   sudo systemctl status jenkins
   # Verify port 8080 in security group
   ```

4. **🐳 Docker Issues**
   ```bash
   sudo systemctl status docker
   sudo usermod -aG docker jenkins
   sudo systemctl restart jenkins
   ```

## ⚙️ Configuration

### 🎛️ Customizable Parameters

Edit `infra/terraform/variables.tf`:
```hcl
variable "instance_type" {
  default = "t3.small"  # Change for different performance
}

variable "aws_region" {
  default = "us-east-1"  # Change for different region
}
```

Edit `infra/ansible/group_vars/all.yml`:
```yaml
project_name: "vle7-app"      # Change app name
app_port: 3000                # Change app port
k8s_namespace: "default"      # Change namespace
```

### 🎨 Customize Application

1. **Update Application Code**: Edit `app/server.js`
2. **Change Container**: Modify `app/Dockerfile`
3. **Update Resources**: Edit `app/k8s/deployment-*.yaml`
4. **Modify Pipeline**: Update `Jenkinsfile`

## 🔒 Security Features

- 🛡️ **Security Groups**: Restrict access to required ports only
- 👤 **IAM Roles**: Minimal required permissions
- 🐳 **Docker Security**: Jenkins user access only
- 🔐 **SSH Keys**: Key-based authentication
- ☸️ **Kubernetes RBAC**: Namespace isolation

## 📈 Production Considerations

For production deployments, consider:

- 🏭 **EKS/GKE**: Instead of Minikube
- 📊 **Monitoring**: Prometheus, Grafana
- 📝 **Logging**: ELK stack, Fluentd
- 🔒 **Secrets**: Kubernetes secrets, Vault
- 🌐 **Load Balancer**: ALB, ingress controllers
- 📱 **Notifications**: Slack, email alerts
- 💾 **Backup**: Database, persistent volumes

## 🤝 Contributing

1. 🍴 Fork the repository
2. 🌱 Create feature branch (`git checkout -b feature/amazing-feature`)
3. 💪 Make changes and test thoroughly
4. 📝 Update documentation if needed
5. 🚀 Submit pull request

## 📄 License

This project is for educational and demonstration purposes.

---

## 🎉 Quick Reference

### 🚀 One-Line Setup
```bash
./init.sh
```

### 🔧 Essential Commands
```bash
# Complete one-command setup
./init.sh

# Check system status
./scripts/status-check.sh

# Manual deployment steps (if needed)
cd infra/terraform && terraform apply
cd .. && ansible-playbook -i ansible/inventory.ini ansible/jenkins_setup.yml

# Access Jenkins (get IP from status-check.sh)
# http://<instance-ip>:8080

# SSH to instance
ssh -i ~/.ssh/yasinkey.pem ec2-user@<instance-ip>

# Check deployments
kubectl get all -l app=vle7-app

# Access app
minikube service vle7-app-service --url

# Pipeline management
# Jenkins: http://<instance-ip>:8080/job/vle7-app-pipeline/
```

### 🆘 Need Help?
- 📋 Check pipeline logs in Jenkins
- ☸️ Configure Kubernetes: `./scripts/configure-kubernetes.sh`
- 🔍 Check status: `./scripts/status-check.sh`
- 📝 SSH to instance: `ssh -i ~/.ssh/yasinkey.pem ec2-user@<ip>`
- � Restart services if needed

### 💾 Memory Optimization
This setup is optimized for t3.small instances:
- ❌ No Docker daemon on Jenkins instance
- ✅ Lightweight nginx containers
- ✅ Remote Kubernetes cluster support
- ✅ Minimal resource usage

**Happy Blue-Green Deploying! 🎊**
# Test webhook trigger - Wed Oct 15 23:10:32 IST 2025
# Test kubectl fix - Wed Oct 15 23:15:34 IST 2025
# Build: 2025-10-15 23:27:41

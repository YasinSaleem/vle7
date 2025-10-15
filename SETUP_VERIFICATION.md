# VLE7 Setup Verification Checklist

## 📋 Complete Setup Verification

Run this checklist after executing `./init.sh` to ensure everything is properly configured.

### ✅ 1. Infrastructure Verification

```bash
# Check Terraform state
cd infra/terraform
terraform show | grep -E "(public_ip|jenkins_url)"

# Verify outputs
terraform output
```

**Expected outputs:**
- ✅ `instance_public_ip` = "X.X.X.X"
- ✅ `jenkins_url` = "http://X.X.X.X:8080"
- ✅ `ssh_command` = "ssh -i ~/.ssh/yasinkey.pem ec2-user@X.X.X.X"

### ✅ 2. Ansible Configuration Verification

```bash
# Check inventory was generated
cat infra/ansible/inventory.ini

# Test connectivity
cd infra
ansible jenkins -i ansible/inventory.ini -m ping
```

**Expected results:**
- ✅ Inventory contains correct IP address
- ✅ Ping successful with "pong" response

### ✅ 3. Jenkins Accessibility

```bash
# Test Jenkins URL (from your local machine)
curl -I http://<instance-ip>:8080

# Or open in browser
open http://<instance-ip>:8080
```

**Expected results:**
- ✅ HTTP 200 OK response
- ✅ Jenkins login page loads

### ✅ 4. SSH Connectivity

```bash
ssh -i ~/.ssh/yasinkey.pem ec2-user@<instance-ip> "echo 'SSH working'"
```

**Expected results:**
- ✅ "SSH working" message appears
- ✅ No authentication errors

### ✅ 5. Services Status (on EC2 instance)

```bash
ssh -i ~/.ssh/yasinkey.pem ec2-user@<instance-ip> << 'EOF'
echo "=== Jenkins Status ==="
sudo systemctl status jenkins --no-pager | head -5

echo "=== Docker Status ==="
sudo systemctl status docker --no-pager | head -5

echo "=== Minikube Status ==="
sudo -u jenkins minikube status
EOF
```

**Expected results:**
- ✅ Jenkins: "active (running)"
- ✅ Docker: "active (running)"
- ✅ Minikube: "Running" cluster status

### ✅ 6. Kubernetes Cluster

```bash
ssh -i ~/.ssh/yasinkey.pem ec2-user@<instance-ip> << 'EOF'
sudo -u jenkins kubectl cluster-info
sudo -u jenkins kubectl get nodes
sudo -u jenkins kubectl get namespaces
EOF
```

**Expected results:**
- ✅ Cluster info shows running control plane
- ✅ minikube node in "Ready" status
- ✅ Default namespaces present

### ✅ 7. Jenkins Pipeline Job

```bash
# Check if pipeline job was created
ssh -i ~/.ssh/yasinkey.pem ec2-user@<instance-ip> << 'EOF'
ls -la /var/lib/jenkins/jobs/
EOF
```

**Expected results:**
- ✅ `vle7-app-pipeline` directory exists
- ✅ `config.xml` file present

### ✅ 8. Application Files

```bash
# Verify all files are in place
find . -name "*.yaml" -o -name "*.yml" -o -name "Jenkinsfile" -o -name "init.sh" | sort
```

**Expected files:**
- ✅ `./Jenkinsfile`
- ✅ `./init.sh`
- ✅ `./app/k8s/deployment-blue.yaml`
- ✅ `./app/k8s/deployment-green.yaml`
- ✅ `./app/k8s/service.yaml`
- ✅ `./app/k8s/kustomization.yaml`
- ✅ `./infra/terraform/*.tf`
- ✅ `./infra/ansible/*.yml`

### ✅ 9. Pipeline Test (Optional)

```bash
# Trigger a test build (via Jenkins UI)
# 1. Open http://<instance-ip>:8080
# 2. Login with admin credentials
# 3. Open vle7-app-pipeline
# 4. Click "Build with Parameters"
# 5. Choose "blue" deployment
# 6. Check "Skip Docker Build"
# 7. Click "Build"
```

**Expected results:**
- ✅ Pipeline starts successfully
- ✅ Blue deployment creates pods
- ✅ Service is accessible

### ✅ 10. GitHub Webhook Setup

To complete the automation:

1. **Go to your GitHub repository settings**
2. **Click "Webhooks" → "Add webhook"**
3. **Set Payload URL**: `http://<instance-ip>:8080/github-webhook/`
4. **Content type**: `application/json`
5. **Events**: Select "Just the push event"
6. **Click "Add webhook"**

**Test webhook:**
- ✅ Make a small commit to main branch
- ✅ Pipeline should trigger automatically
- ✅ Check Jenkins for new build

## 🚨 Troubleshooting Common Issues

### Issue: Jenkins not accessible
```bash
# Check security group allows port 8080
aws ec2 describe-security-groups --group-names jenkins-security-group

# Check Jenkins service
ssh -i ~/.ssh/yasinkey.pem ec2-user@<instance-ip> "sudo systemctl restart jenkins"
```

### Issue: Minikube not working
```bash
ssh -i ~/.ssh/yasinkey.pem ec2-user@<instance-ip> << 'EOF'
sudo -u jenkins minikube delete
sudo -u jenkins minikube start --driver=docker --memory=1024
EOF
```

### Issue: Pipeline fails
```bash
# Check kubectl access
ssh -i ~/.ssh/yasinkey.pem ec2-user@<instance-ip> "sudo -u jenkins kubectl get nodes"

# Check Docker access
ssh -i ~/.ssh/yasinkey.pem ec2-user@<instance-ip> "sudo -u jenkins docker ps"
```

### Issue: Pods in CrashLoopBackOff
```bash
ssh -i ~/.ssh/yasinkey.pem ec2-user@<instance-ip> << 'EOF'
sudo -u jenkins kubectl get pods
sudo -u jenkins kubectl describe pod <pod-name>
sudo -u jenkins kubectl logs <pod-name>
EOF
```

## 🎯 Success Criteria

Your VLE7 setup is complete when:

- ✅ **Infrastructure**: Terraform created EC2 instance with correct security groups
- ✅ **Configuration**: Ansible configured Jenkins with all required plugins
- ✅ **Accessibility**: Jenkins dashboard accessible via web browser
- ✅ **Services**: Jenkins, Docker, and Minikube all running
- ✅ **Pipeline**: vle7-app-pipeline job created and functional
- ✅ **Kubernetes**: Cluster accessible with kubectl
- ✅ **Automation**: GitHub webhook triggers pipeline (optional but recommended)

## 🎉 You're Ready!

Once all items are ✅, your VLE7 blue-green deployment pipeline is fully operational!

### Next Steps:
1. **🧪 Test the pipeline** with both blue and green deployments
2. **🔗 Set up GitHub webhook** for automatic triggers
3. **🎨 Customize the application** in `app/server.js`
4. **📊 Monitor deployments** using Jenkins and kubectl
5. **💰 Manage costs** by stopping/starting the EC2 instance when not in use

**Happy Deploying! 🚀**
# GitHub + Jenkins Setup Guide

This guide walks you through setting up automated CI/CD with GitHub and Jenkins for blue-green deployment.

## Prerequisites
- ✅ Jenkins server running (from previous Ansible setup)
- ✅ Docker installed on Jenkins server
- ✅ kubectl configured on Jenkins server
- ✅ Application code ready in `app/` directory

## Step 1: Create GitHub Repository

1. Go to [GitHub](https://github.com) and click **"New repository"**
2. Name it: `your-username/your-app-name` (e.g., `johndoe/myapp`)
3. Set to **Public** (easier for webhooks)
4. **Don't** initialize with README (we have existing code)
5. Click **"Create repository"**

## Step 2: Push Your Code

```bash
# If you haven't already, initialize git in your project
cd /path/to/your/project
git init
git add .
git commit -m "Initial DevOps setup with blue-green deployment"

# Add your GitHub repo as origin
git remote add origin https://github.com/your-username/your-app-name.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Step 3: Add Repository Secrets

1. Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"** and add:

| Secret Name | Value | Purpose |
|-------------|-------|---------|
| `DOCKERHUB_USERNAME` | `your-dockerhub-username` | Docker registry login |
| `DOCKERHUB_TOKEN` | `your-dockerhub-token` | Docker registry password |

### Get DockerHub Token:
1. Go to [Docker Hub](https://hub.docker.com) → Account Settings → Security
2. Click **"New Access Token"**
3. Name: `jenkins-ci`, Permissions: **Read, Write, Delete**
4. Copy the generated token

## Step 4: Configure Jenkins

### 4.1 Install Required Plugins
1. Jenkins Dashboard → **Manage Jenkins** → **Plugins**
2. Install these plugins:
   - **GitHub Integration Plugin**
   - **Docker Pipeline Plugin**  
   - **Kubernetes CLI Plugin**

### 4.2 Add Credentials
1. **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. Add **Username with password**:
   - **ID**: `dockerhub-creds`
   - **Username**: Your DockerHub username
   - **Password**: Your DockerHub token
   - **Description**: `DockerHub Credentials`

### 4.3 Create Pipeline Job
1. **New Item** → **Pipeline** → Name: `myapp-blue-green`
2. **Pipeline** section:
   - **Definition**: `Pipeline script from SCM`
   - **SCM**: `Git`
   - **Repository URL**: `https://github.com/your-username/your-app-name.git`
   - **Branch**: `*/main`
   - **Script Path**: `Jenkinsfile`
3. **Save**

## Step 5: Setup GitHub Webhook (Optional - for Auto-trigger)

1. GitHub repo → **Settings** → **Webhooks** → **Add webhook**
2. **Payload URL**: `http://YOUR_EC2_IP:8080/github-webhook/`
   - Replace `YOUR_EC2_IP` with your actual EC2 public IP
3. **Content type**: `application/json`
4. **Which events**: `Just the push event`
5. **Active**: ✅ Checked
6. **Add webhook**

> **Note**: If webhook doesn't work (common with public repos), you can manually trigger builds in Jenkins.

## Step 6: Configure Automatic Pipeline Triggers

### 6.1 Enable GitHub Integration in Jenkins
1. **Manage Jenkins** → **Configure System**
2. Scroll to **GitHub** section
3. **Add GitHub Server**:
   - **Name**: `GitHub`
   - **API URL**: `https://api.github.com` (default)
   - **Credentials**: Leave blank for public repos
4. **Test connection** and **Save**

### 6.2 Configure Job for Push Events
1. Go to your pipeline job → **Configure**
2. **Build Triggers** section:
   - ✅ Check **"GitHub hook trigger for GITScm polling"**
   - ✅ Check **"Poll SCM"** (leave schedule empty)
3. **Save**

Now your pipeline will automatically trigger when you push to GitHub!

## Step 7: Test Your Pipeline

### Option A: Manual Trigger
1. Go to Jenkins → Your pipeline job
2. Click **"Build with Parameters"**
3. Select **Color**: `blue` or `green`
4. Click **"Build"**

### Option B: Git Push Trigger
```bash
# Make a small change and push
echo "# Updated $(date)" >> README.md
git add README.md
git commit -m "Test webhook trigger"
git push origin main
```

## Step 8: Validate Blue-Green Deployment

### 8.1 Make Application Changes
1. **Edit your application code**:
   ```bash
   # Example: Update version in app/package.json
   cd app
   vim server.js  # Change version or add new feature
   ```

2. **Update version/build info**:
   ```javascript
   // In server.js, change something visible
   <p><strong>Version:</strong> 2.0.0</p>  // Changed from 1.0.0
   <p><strong>Feature:</strong> New Blue-Green Pipeline!</p>  // New line
   ```

### 8.2 Trigger Deployment
```bash
# Commit and push changes
git add .
git commit -m "feat: Update to v2.0.0 with new features"
git push origin main
```

### 8.3 Watch the Blue-Green Process
1. **Jenkins Dashboard**: Watch build progress in real-time
2. **Pipeline stages**:
   - ✅ **Clone** → Gets latest code
   - ✅ **Build** → Creates new Docker image with build number
   - ✅ **Push** → Uploads to DockerHub
   - ✅ **Deploy** → Deploys to inactive environment (green)
   - ⏳ **Manual Approval** → You decide when to switch traffic
   - ✅ **Switch Traffic** → Service points to new version
   - ✅ **Cleanup** → Optionally removes old deployment

### 8.4 Validation Steps
```bash
# Monitor deployments
kubectl get deployments -l app=myapp -w

# Check which version is active
kubectl get service myapp-service -o jsonpath='{.spec.selector}'

# Test the application
kubectl port-forward svc/myapp-service 8080:80
# Visit http://localhost:8080 to see your changes
```

## Step 9: Monitor Deployment

1. **Jenkins Console**: Watch build logs in real-time
2. **Kubernetes**: 
   ```bash
   kubectl get pods -l app=myapp -o wide
   kubectl get svc myapp-service
   ```
3. **Application**: Access via `kubectl port-forward svc/myapp-service 8080:80`

## Troubleshooting

### Common Issues:

**🔴 Webhook not triggering?**
- Check EC2 security group allows port 8080 from GitHub IPs
- Try manual build first to verify pipeline works

**🔴 Docker push fails?**
- Verify DockerHub credentials in Jenkins
- Check credential ID matches `dockerhub-creds` in Jenkinsfile

**🔴 kubectl commands fail?**
- Ensure Jenkins user has kubeconfig access
- Check if minikube is running: `minikube status`

**🔴 Blue-green switch not working?**
- Verify both deployments are ready: `kubectl get deployments`
- Check service selector: `kubectl get svc myapp-service -o yaml`

## Quick Commands

```bash
# Check pipeline status
kubectl get pods,svc,deployments -l app=myapp

# Switch traffic manually
kubectl patch service myapp-service -p '{"spec":{"selector":{"color":"green"}}}'

# View application
kubectl port-forward svc/myapp-service 8080:80
# Then visit http://localhost:8080

# Rollback if needed
kubectl rollout undo deployment/myapp-blue
```

## Step 10: Complete Blue-Green Workflow Example

Here's what happens in a typical deployment:

### 🔵 **Current State**: Blue is Live
```bash
kubectl get service myapp-service -o jsonpath='{.spec.selector.color}'
# Output: blue
```

### 🟢 **Deploy to Green**: New Version
1. **Code Change**: Update `app/server.js` with new features
2. **Git Push**: `git push origin main`
3. **Jenkins Pipeline**:
   - Builds new Docker image: `myapp:build-15`
   - Deploys to **green** environment (inactive)
   - Runs health checks on green pods
   - **Pauses for manual approval** ⏸️

### ✅ **Manual Validation**
```bash
# Test green deployment before switching traffic
kubectl port-forward svc/myapp-green 8081:8080
curl http://localhost:8081  # Test new version
```

### 🔄 **Traffic Switch**
1. **Approve in Jenkins**: Click "Proceed with Traffic Switch"
2. **Service Update**: Points to green pods
3. **Validation**: Confirms green is receiving traffic
4. **Cleanup**: Optionally scales down blue deployment

### 🎯 **Result**: Green is Now Live
```bash
kubectl get service myapp-service -o jsonpath='{.spec.selector.color}'
# Output: green
```

## Success! 🎉

Your automated blue-green deployment pipeline is now ready:
- **Code push** → **GitHub webhook** → **Jenkins auto-trigger** → **Docker build** → **Kubernetes deploy to inactive** → **Manual approval** → **Traffic switch** → **Zero downtime deployment** ✨

### Next Deployment Workflow:
1. Make code changes
2. `git push origin main`
3. Watch Jenkins pipeline automatically:
   - Build and test
   - Deploy to inactive environment  
   - Wait for your approval
   - Switch traffic seamlessly
4. **Zero downtime achieved!** 🚀
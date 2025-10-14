# GitHub Webhook Setup - REQUIRED FOR FULL MARKS

## Critical: This setup is needed to achieve 6/6 marks (1.0 point missing)

### Step 1: Set Up GitHub Repository

1. **Create GitHub Repository**:
   ```bash
   # If not already done
   cd /Users/yasinsaleem/CourseWork/DevOps/vle7
   git init
   git add .
   git commit -m "Complete DevOps pipeline with blue-green deployment"
   
   # Create repo on GitHub: https://github.com/new
   # Name: vle7-devops (or similar)
   
   git remote add origin https://github.com/YasinSaleem/vle7-devops.git
   git push -u origin main
   ```

### Step 2: Configure Jenkins for GitHub Integration

**CRITICAL: Jenkins must be accessible from GitHub for webhooks**

1. **Install Required Jenkins Plugins**:
   - Go to Jenkins → Manage Jenkins → Plugins
   - Install: "GitHub Integration Plugin"
   - Install: "Generic Webhook Trigger Plugin" 

2. **Create Pipeline Job**:
   - New Item → Pipeline → Name: "vle7-blue-green"
   - Pipeline from SCM → Git
   - Repository URL: `https://github.com/YasinSaleem/vle7-devops.git`
   - Script Path: `Jenkinsfile`

3. **Enable Webhook Triggers**:
   - Job → Configure → Build Triggers
   - ✅ Check "GitHub hook trigger for GITScm polling"
   - ✅ Check "Poll SCM" (backup method)

### Step 3: Add GitHub Webhook

**Webhook URL**: `http://50.17.77.114:8080/github-webhook/`

1. **GitHub Repository → Settings → Webhooks → Add webhook**:
   - **Payload URL**: `http://50.17.77.114:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Which events**: "Just the push event"
   - **Active**: ✅ Checked

2. **Test Webhook**:
   ```bash
   # Make a small change
   echo "Testing webhook $(date)" >> README.md
   git add README.md
   git commit -m "test: trigger webhook"
   git push origin main
   ```

### Step 4: Verify Auto-Trigger Works

**Expected Behavior**:
- Push to GitHub → Webhook fires → Jenkins builds automatically
- This demonstrates "automated pipeline builds and deploys on Git push" (TC4)

### Alternative: SCM Polling (Backup Method)

If webhook fails due to network issues:

1. **Jenkins Job → Configure → Build Triggers**
2. **Poll SCM**: `H/2 * * * *` (every 2 minutes)
3. **Push changes and wait max 2 minutes**

### Test Case Validation

After setup, verify:
- ✅ **TC4**: Pipeline auto-triggers on Git push
- ✅ **GitHub Integration**: Jenkins responds to repository changes
- ✅ **Auto-deployment**: Complete CI/CD workflow triggered by code changes

**This completes the 6th requirement for full marks (6/6)!**

## Quick Setup Commands

```bash
# 1. Commit current state
git add .
git commit -m "Complete blue-green DevOps pipeline"

# 2. Push to GitHub (create repo first)
git remote add origin https://github.com/YasinSaleem/vle7-devops.git
git push -u origin main

# 3. Configure Jenkins (via web interface)
# - Install GitHub Integration Plugin
# - Create pipeline job pointing to your repo
# - Enable webhook triggers

# 4. Add webhook in GitHub
# URL: http://50.17.77.114:8080/github-webhook/

# 5. Test
echo "Webhook test $(date)" >> README.md
git add README.md
git commit -m "test: auto-trigger"
git push origin main

# 6. Verify Jenkins builds automatically
```

**Result**: ✅ **6/6 marks achieved** with automated GitHub integration!
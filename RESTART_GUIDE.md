# 🚀 RESTART GUIDE - VLE7 Blue-Green Deployment

## 💰 CURRENT STATUS: STOPPED ✅
- **Cost**: $0/hour (only ~$0.80/month for storage)
- **Instance**: i-0141f4c498770a53c (STOPPED)
- **All data preserved**: Jenkins, Docker, Minikube configurations intact

## 🔄 HOW TO RESTART

### Step 1: Start the Instance
```bash
aws ec2 start-instances --instance-ids i-0141f4c498770a53c
```

### Step 2: Get New IP Address (it will change!)
```bash
aws ec2 describe-instances --instance-ids i-0141f4c498770a53c --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

### Step 3: Test SSH Connection
```bash
# Replace NEW_IP with the IP from Step 2
ssh -i ~/.ssh/yasinkey.pem ec2-user@NEW_IP "echo 'Connected!' && uptime"
```

### Step 4: Verify Services (should auto-start)
```bash
ssh -i ~/.ssh/yasinkey.pem ec2-user@NEW_IP "
sudo systemctl status jenkins --no-pager
sudo -u jenkins bash -c 'export PATH=/usr/local/bin:\$PATH && minikube status'
"
```

### Step 5: Access Jenkins
- **URL**: http://NEW_IP:8080 
- **Your credentials**: (same as before)

### Step 6: Update GitHub Webhook (if needed)
- Go to: https://github.com/YasinSaleem/vle7/settings/hooks
- Update webhook URL to: http://NEW_IP:8080/github-webhook/

## 🎯 TEST THE MINIMAL PIPELINE

1. **Go to Jenkins**: http://NEW_IP:8080/job/vle7-blue-green-deployment/
2. **Build with Parameters**: COLOR = `blue`
3. **Expected time**: ~1-2 minutes (much faster now!)
4. **Features**: No Docker build, lightweight nginx, simple blue-green switching

## 💡 WHAT'S READY TO TEST

✅ **Minimal Jenkinsfile**: No Docker operations, uses nginx:alpine  
✅ **Optimized Memory**: 274MB available (was only 175MB)  
✅ **Faster Pipeline**: ~1 minute vs 5+ minutes  
✅ **Blue-Green Demo**: Simple traffic switching  
✅ **All Configs Preserved**: Jenkins jobs, credentials, minikube setup  

## 🛑 TO STOP AGAIN
```bash
aws ec2 stop-instances --instance-ids i-0141f4c498770a53c
```

---
**Remember**: Instance will get a new IP each time you start/stop it!
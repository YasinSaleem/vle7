# 🚨 CLEANUP INSTRUCTIONS - DESTROY EVERYTHING ASAP 🚨

## ⚠️ COST WARNING
- **t3.small instance**: ~$0.0208/hour = ~$15/month
- **Running costs accumulate 24/7** - destroy when not needed!

## 🛑 EMERGENCY CLEANUP (Most Important)

### Option 1: Quick Terraform Destroy (RECOMMENDED)
```bash
cd /Users/yasinsaleem/CourseWork/DevOps/vle7/infra/terraform
terraform destroy -auto-approve
```

### Option 2: AWS Console Emergency Stop
1. Go to AWS Console → EC2 → Instances
2. Find instance: `study-server` (currently: i-0141f4c498770a53c at 54.221.124.93)
3. Right-click → Terminate instance

## 📋 COMPLETE CLEANUP CHECKLIST

### 1. Destroy Terraform Infrastructure ✅
```bash
cd /Users/yasinsaleem/CourseWork/DevOps/vle7/infra/terraform
terraform destroy
```
**This removes:**
- EC2 instance (t3.small)
- Security group
- IAM roles and policies
- Instance profile

### 2. Clean Up Local Docker Images 🐳
```bash
docker rmi yasinsaleem/myapp:* || true
docker system prune -f
```

### 3. Stop Local Services 🔧
```bash
# If minikube was started locally
minikube stop
minikube delete

# Clean Docker
docker system prune -a -f
```

### 4. GitHub Webhook Cleanup (Optional) 🔗
1. Go to: https://github.com/YasinSaleem/vle7/settings/hooks
2. Delete webhook: http://54.221.124.93:8080/github-webhook/

### 5. AWS Console Verification 🔍
Check these AWS services for any remaining resources:
- **EC2**: No running instances
- **EBS**: No unattached volumes  
- **Security Groups**: No custom groups (only default)
- **IAM**: No custom roles starting with "study-"

## 🕐 COST MONITORING

### Current Running Costs:
- **Instance**: t3.small @ $0.0208/hour
- **Storage**: 8GB EBS @ $0.10/GB/month
- **Data Transfer**: Usually free (1GB/month included)

### **Estimated Monthly Cost**: ~$15-20

### Check Your AWS Bill:
1. AWS Console → Billing & Cost Management
2. Bills → Current month
3. Look for EC2 charges

## 🚀 QUICK RESTART (When Needed Again)

### Option 1: Start Existing Instance (Recommended)
```bash
# Start the stopped instance (keeps all data, changes IP)
aws ec2 start-instances --instance-ids i-0141f4c498770a53c

# Get new IP address
aws ec2 describe-instances --instance-ids i-0141f4c498770a53c --query 'Reservations[0].Instances[0].PublicIpAddress'
```

### Option 2: Recreate Everything (if needed)
```bash
cd /Users/yasinsaleem/CourseWork/DevOps/vle7/infra/terraform
terraform plan
terraform apply
# Wait for IP, then update Jenkins/GitHub webhook with new IP
```

## 📞 EMERGENCY CONTACTS

### If You Can't Access AWS Console:
1. **Terraform Destroy**: Always works if you have the state file
2. **AWS CLI**: `aws ec2 terminate-instances --instance-ids i-XXXXXXXXX`
3. **AWS Support**: Contact if charges are unexpected

### Current Instance Details:
- **Instance ID**: i-0141f4c498770a53c
- **Status**: STOPPED (October 14, 2025 - saving costs!)
- **Last IP**: 54.221.124.93 (will change when restarted)
- **Type**: t3.small (2 vCPU, 2GB RAM)

## 🎯 POST-PROJECT CLEANUP

### When VLE7 Project is Complete:
1. ✅ Run `terraform destroy`
2. ✅ Delete local Docker images
3. ✅ Clean up GitHub webhook
4. ✅ Verify $0 AWS charges next month
5. ✅ Keep this repo for future reference

---

## 🔥 CRITICAL: SET A CALENDAR REMINDER
**Add to your calendar**: "Destroy VLE7 infrastructure" for when you're done with the project!

**Remember**: Even a stopped EC2 instance incurs EBS storage costs. TERMINATE (don't just stop) when done.
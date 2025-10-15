#!/bin/bash

# VLE7 Status Check Script
# This script checks the status of all components in the blue-green deployment

set -e

# Configuration
PROJECT_NAME="vle7-app"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] $1${NC}"
}

check_terraform() {
    info "🏗️ Checking Terraform infrastructure..."
    
    cd infra/terraform
    
    if terraform show > /dev/null 2>&1; then
        INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "N/A")
        JENKINS_URL=$(terraform output -raw jenkins_url 2>/dev/null || echo "N/A")
        
        log "✅ Terraform infrastructure is deployed"
        echo "   Instance IP: $INSTANCE_IP"
        echo "   Jenkins URL: $JENKINS_URL"
    else
        warn "⚠️ Terraform infrastructure not found or not deployed"
    fi
    
    cd ../../
}

check_jenkins() {
    info "⚙️ Checking Jenkins status..."
    
    if [ -f "infra/terraform/terraform.tfstate" ]; then
        cd infra/terraform
        INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")
        cd ../../
        
        if [ ! -z "$INSTANCE_IP" ]; then
            if curl -s -f "http://${INSTANCE_IP}:8080" > /dev/null 2>&1; then
                log "✅ Jenkins is accessible at http://${INSTANCE_IP}:8080"
            else
                warn "⚠️ Jenkins not accessible (may still be starting up)"
            fi
        fi
    else
        warn "⚠️ No Terraform state found - infrastructure may not be deployed"
    fi
}

check_system_resources() {
    info "� Checking system resources (on remote instance)..."
    
    if [ -f "infra/terraform/terraform.tfstate" ]; then
        cd infra/terraform
        INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")
        cd ../../
        
        if [ ! -z "$INSTANCE_IP" ] && [ -f ~/.ssh/yasinkey.pem ]; then
            info "Checking system resources on instance..."
            ssh -i ~/.ssh/yasinkey.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@${INSTANCE_IP} << 'EOF'
echo "=== Memory Usage ==="
free -h

echo -e "\n=== Disk Usage ==="
df -h /

echo -e "\n=== CPU Info ==="
nproc && cat /proc/loadavg

echo -e "\n=== Running Services ==="
systemctl status jenkins --no-pager -l | head -10
EOF
        fi
    fi
}

check_kubernetes() {
    info "☸️ Checking Kubernetes status (on remote instance)..."
    
    if [ -f "infra/terraform/terraform.tfstate" ]; then
        cd infra/terraform
        INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")
        cd ../../
        
        if [ ! -z "$INSTANCE_IP" ] && [ -f ~/.ssh/yasinkey.pem ]; then
            info "Checking Kubernetes deployments..."
            ssh -i ~/.ssh/yasinkey.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@${INSTANCE_IP} << 'EOF'
echo "=== Kubernetes Cluster Info ==="
kubectl cluster-info || echo "No Kubernetes cluster configured"

echo -e "\n=== Kubeconfig Status ==="
ls -la ~/.kube/config || echo "No kubeconfig found"

echo -e "\n=== Deployments ==="
kubectl get deployments -l app=vle7-app || echo "No deployments found"

echo -e "\n=== Services ==="
kubectl get services -l app=vle7-app || echo "No services found"

echo -e "\n=== Pods ==="
kubectl get pods -l app=vle7-app || echo "No pods found"

echo -e "\n=== Current Service Selector ==="
kubectl get service vle7-app-service -o jsonpath='{.spec.selector}' 2>/dev/null || echo "Service not found"
echo ""
EOF
        fi
    fi
}

show_access_info() {
    info "🌐 Access Information..."
    
    if [ -f "infra/terraform/terraform.tfstate" ]; then
        cd infra/terraform
        INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "N/A")
        JENKINS_URL=$(terraform output -raw jenkins_url 2>/dev/null || echo "N/A")
        cd ../../
        
        echo ""
        echo "================================================"
        echo "          VLE7 Access Information"
        echo "================================================"
        echo "🖥️  Instance IP: $INSTANCE_IP"
        echo "🌐 Jenkins URL: $JENKINS_URL"
        echo "🔐 SSH Command: ssh -i ~/.ssh/yasinkey.pem ec2-user@$INSTANCE_IP"
        echo ""
        echo "📋 Quick Commands:"
        echo "   • Check status: ssh -i ~/.ssh/yasinkey.pem ec2-user@$INSTANCE_IP 'kubectl get all'"
        echo "   • Access app: ssh -i ~/.ssh/yasinkey.pem ec2-user@$INSTANCE_IP 'minikube service vle7-app-service --url'"
        echo "   • Jenkins logs: ssh -i ~/.ssh/yasinkey.pem ec2-user@$INSTANCE_IP 'sudo journalctl -u jenkins -f'"
        echo ""
        echo "🎯 Pipeline Job URL: ${JENKINS_URL}/job/${PROJECT_NAME}-pipeline/"
        echo "🔗 GitHub Webhook: ${JENKINS_URL}/github-webhook/"
        echo "================================================"
    else
        warn "No infrastructure deployed yet. Run ./init.sh to deploy."
    fi
}

show_next_steps() {
    info "📋 Next Steps..."
    
    echo ""
    echo "==============================================="
    echo "              Next Steps"
    echo "==============================================="
    echo "1. 🌐 Access Jenkins and complete initial setup"
    echo "2. 🔗 Add GitHub webhook for automatic triggers"
    echo "3. 🚀 Run the pipeline job to test deployment"
    echo "4. 🔵🟢 Test blue-green switching"
    echo ""
    echo "🛠️ Management Commands:"
    echo "   • Deploy: ./init.sh"
    echo "   • Status: ./scripts/status-check.sh"
    echo "   • Destroy: cd infra/terraform && terraform destroy"
    echo "==============================================="
}

main() {
    log "🔍 VLE7 Blue-Green Deployment Status Check"
    echo ""
    
    check_terraform
    echo ""
    check_jenkins
    echo ""
    check_system_resources
    echo ""
    check_kubernetes
    echo ""
    show_access_info
    echo ""
    show_next_steps
    
    log "✅ Status check completed!"
}

main "$@"
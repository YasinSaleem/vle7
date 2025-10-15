#!/bin/bash

# Kubernetes Configuration Helper for VLE7
# This script helps configure kubectl access to your Kubernetes cluster

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"
}

show_cluster_options() {
    echo ""
    echo "=========================================="
    echo "    Kubernetes Cluster Configuration"
    echo "=========================================="
    echo ""
    echo "Choose your Kubernetes cluster type:"
    echo ""
    echo "1. 🌩️  AWS EKS (Elastic Kubernetes Service)"
    echo "2. 🌐 Google GKE (Google Kubernetes Engine)"
    echo "3. 🔷 Azure AKS (Azure Kubernetes Service)"
    echo "4. 🐳 Local Kind (Kubernetes in Docker)"
    echo "5. 📋 Manual kubeconfig upload"
    echo "6. ❌ Skip configuration"
    echo ""
    read -p "Enter your choice (1-6): " choice
    
    case $choice in
        1) configure_eks ;;
        2) configure_gke ;;
        3) configure_aks ;;
        4) configure_kind ;;
        5) configure_manual ;;
        6) skip_configuration ;;
        *) error "Invalid choice. Please run again." && exit 1 ;;
    esac
}

configure_eks() {
    log "Configuring AWS EKS access..."
    
    read -p "Enter your EKS cluster name: " cluster_name
    read -p "Enter AWS region (default: us-east-1): " region
    region=${region:-us-east-1}
    
    if [ -f "infra/terraform/terraform.tfstate" ]; then
        cd infra/terraform
        INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")
        cd ../../
        
        if [ ! -z "$INSTANCE_IP" ] && [ -f ~/.ssh/yasinkey.pem ]; then
            info "Configuring EKS access on Jenkins instance..."
            ssh -i ~/.ssh/yasinkey.pem -o StrictHostKeyChecking=no ec2-user@${INSTANCE_IP} << EOF
# Configure EKS access
aws eks update-kubeconfig --region ${region} --name ${cluster_name}

# Copy config for jenkins user
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/config
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
sudo chmod 600 /var/lib/jenkins/.kube/config

# Test connection
kubectl cluster-info
echo "EKS configuration completed!"
EOF
            log "✅ EKS configuration completed!"
        else
            error "Cannot connect to Jenkins instance. Please check terraform state and SSH key."
        fi
    else
        error "Terraform state not found. Please run ./init.sh first."
    fi
}

configure_gke() {
    log "Configuring Google GKE access..."
    
    read -p "Enter your GKE cluster name: " cluster_name
    read -p "Enter GCP project ID: " project_id
    read -p "Enter GCP zone/region: " zone
    
    warn "Note: This requires gcloud CLI to be installed and configured on the Jenkins instance."
    info "Manual steps needed on Jenkins instance:"
    echo "1. Install gcloud CLI"
    echo "2. gcloud auth login"
    echo "3. gcloud container clusters get-credentials ${cluster_name} --zone ${zone} --project ${project_id}"
}

configure_aks() {
    log "Configuring Azure AKS access..."
    
    read -p "Enter your AKS cluster name: " cluster_name
    read -p "Enter resource group name: " resource_group
    
    warn "Note: This requires Azure CLI to be installed and configured on the Jenkins instance."
    info "Manual steps needed on Jenkins instance:"
    echo "1. Install Azure CLI"
    echo "2. az login"
    echo "3. az aks get-credentials --resource-group ${resource_group} --name ${cluster_name}"
}

configure_kind() {
    log "Configuring Kind (Kubernetes in Docker)..."
    
    warn "Kind requires Docker, which is not installed to save memory."
    info "Alternative: Use a lightweight Kubernetes distribution like k3s:"
    echo "1. SSH to Jenkins instance"
    echo "2. curl -sfL https://get.k3s.io | sh -"
    echo "3. sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config"
    echo "4. sudo chown ec2-user:ec2-user ~/.kube/config"
}

configure_manual() {
    log "Manual kubeconfig configuration..."
    
    info "To manually configure kubeconfig:"
    echo "1. Get your cluster's kubeconfig file"
    echo "2. Copy it to the Jenkins instance at ~/.kube/config"
    echo "3. Set proper permissions: chmod 600 ~/.kube/config"
    echo "4. Copy to Jenkins user: sudo cp ~/.kube/config /var/lib/jenkins/.kube/config"
    echo "5. Fix ownership: sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config"
    
    if [ -f "infra/terraform/terraform.tfstate" ]; then
        cd infra/terraform
        INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")
        cd ../../
        
        if [ ! -z "$INSTANCE_IP" ]; then
            echo ""
            echo "Your Jenkins instance IP: ${INSTANCE_IP}"
            echo "SSH command: ssh -i ~/.ssh/yasinkey.pem ec2-user@${INSTANCE_IP}"
        fi
    fi
}

skip_configuration() {
    warn "Skipping Kubernetes configuration."
    info "You can configure it later by:"
    echo "1. SSH to Jenkins instance"
    echo "2. Configure ~/.kube/config"
    echo "3. Copy config to jenkins user"
    echo "4. Test with: kubectl cluster-info"
}

show_final_info() {
    echo ""
    echo "=========================================="
    echo "       Configuration Complete"
    echo "=========================================="
    echo ""
    echo "📋 Next Steps:"
    echo "1. Test kubectl connection: kubectl cluster-info"
    echo "2. Deploy blue-green manifests: kubectl apply -f app/k8s/"
    echo "3. Run Jenkins pipeline to test deployment"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "• Check kubeconfig: kubectl config view"
    echo "• Verify context: kubectl config current-context"
    echo "• Test connectivity: kubectl get nodes"
    echo ""
    echo "✅ Happy deploying!"
    echo "=========================================="
}

main() {
    log "🔧 VLE7 Kubernetes Configuration Helper"
    
    show_cluster_options
    show_final_info
}

main "$@"
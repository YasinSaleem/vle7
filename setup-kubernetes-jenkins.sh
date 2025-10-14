#!/bin/bash

# Final Setup Script for Jenkins Server - Required for Kubernetes Integration
# Run this on EC2 instance to complete the setup

echo "🔧 Final Jenkins-Kubernetes Setup for VLE7..."

# Check if running as jenkins user, if not switch
if [ "$USER" != "jenkins" ]; then
    echo "⚠️  This script should be run as jenkins user for proper permissions"
    echo "💡 Switching to jenkins user..."
    sudo -i -u jenkins bash << 'JENKINS_SETUP'
        echo "🚀 Setting up Kubernetes environment for Jenkins..."
        
        # Install minikube if not present
        if ! command -v minikube &> /dev/null; then
            echo "📦 Installing minikube..."
            curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
            sudo install minikube-linux-amd64 /usr/local/bin/minikube
        fi
        
        # Start minikube
        echo "🚀 Starting minikube cluster..."
        minikube start --driver=docker --cpus=2 --memory=2048
        
        # Verify setup
        echo "✅ Verifying setup..."
        kubectl get nodes
        minikube status
        
        echo "🎯 Jenkins-Kubernetes setup complete!"
JENKINS_SETUP
    exit 0
fi

# If already jenkins user, run setup directly
echo "🚀 Setting up Kubernetes environment for Jenkins..."

# Install minikube if not present
if ! command -v minikube &> /dev/null; then
    echo "📦 Installing minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
fi

# Start minikube
echo "🚀 Starting minikube cluster..."
minikube start --driver=docker --cpus=2 --memory=2048

# Verify setup
echo "✅ Verifying setup..."
kubectl get nodes
minikube status

echo "🎯 Jenkins-Kubernetes setup complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Access Jenkins: http://50.17.77.114:8080"
echo "2. Set up GitHub webhook integration"
echo "3. Test the complete blue-green pipeline"
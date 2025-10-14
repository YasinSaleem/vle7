#!/bin/bash

# Setup script to install and configure minikube on Jenkins server
# Run this on the EC2 instance to complete the Jenkins-Kubernetes setup

echo "🔧 Setting up Minikube for Jenkins pipeline..."

# Add minikube to jenkins user's PATH
sudo tee -a /var/lib/jenkins/.bashrc << 'EOF'
export PATH=/usr/local/bin:$PATH
EOF

# Start minikube as jenkins user
echo "🚀 Starting minikube cluster..."
sudo -i -u jenkins bash << 'EOF'
export PATH=/usr/local/bin:$PATH
minikube start --driver=docker --cpus=2 --memory=2048
minikube status
kubectl get nodes
EOF

# Load the Docker image we built earlier
echo "📦 Loading Docker image into minikube..."
sudo -i -u jenkins bash << 'EOF'
export PATH=/usr/local/bin:$PATH
# If you have the image locally, load it:
# docker save yasinsaleem/myapp:localtest | minikube image load -
minikube image ls
EOF

echo "✅ Minikube setup complete!"
echo ""
echo "🎯 Next steps:"
echo "1. Test Jenkins pipeline by triggering a build"
echo "2. The pipeline will now work with minikube on the server"
echo "3. Access Jenkins at: http://107.20.125.134:8080"
echo ""
echo "📋 Useful commands for troubleshooting:"
echo "sudo -i -u jenkins minikube status"
echo "sudo -i -u jenkins kubectl get pods"
echo "sudo -i -u jenkins kubectl get svc"
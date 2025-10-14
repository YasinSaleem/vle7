pipeline {
    agent any
    
    parameters {
        choice(
            name: 'COLOR',
            choices: ['green', 'blue'],
            description: 'Deployment color for blue-green deployment'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip test stages'
        )
    }
    
    environment {
        IMAGE = "yasinsaleem/myapp:${BUILD_NUMBER}"
        REGISTRY = "docker.io"
        COLOR = "${params.COLOR}"
        KUBECONFIG_FILE = "/var/lib/jenkins/.kube/config"
    }
    
    stages {
        stage('Initialize') {
            steps {
                script {
                    echo "🚀 Starting Blue-Green Deployment Pipeline"
                    echo "📦 Build Number: ${BUILD_NUMBER}"
                    echo "🎨 Target Color: ${COLOR}"
                    echo "🐳 Docker Image: ${IMAGE}"
                    
                    // Determine previous color for rollback
                    def previousColor = (COLOR == 'blue') ? 'green' : 'blue'
                    echo "🔄 Previous Color (for rollback): ${previousColor}"
                }
            }
        }
        
        stage('Clone Repo') {
            steps {
                echo "📁 Cloning repository..."
                checkout scm
                script {
                    // Display repository info
                    sh 'echo "Repository cloned successfully"'
                    sh 'ls -la'
                    sh 'echo "Current directory: $(pwd)"'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image: ${IMAGE}"
                script {
                    try {
                        // Build the Docker image
                        sh """
                            cd app
                            echo "Building Docker image with tag: ${IMAGE}"
                            docker build -t ${IMAGE} .
                            docker images | grep myapp
                        """
                        echo "✅ Docker image built successfully!"
                    } catch (Exception e) {
                        echo "❌ Docker build failed: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
        
        stage('Push Image to Registry') {
            steps {
                echo "📤 Pushing image to Docker Hub..."
                script {
                    try {
                        withCredentials([usernamePassword(
                            credentialsId: 'dockerhub-creds',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )]) {
                            sh """
                                echo "Logging into Docker Hub..."
                                echo \$DOCKER_PASS | docker login ${REGISTRY} -u \$DOCKER_USER --password-stdin
                                
                                echo "Pushing image: ${IMAGE}"
                                docker push ${IMAGE}
                                
                                echo "Logout from Docker Hub"
                                docker logout ${REGISTRY}
                            """
                        }
                        echo "✅ Image pushed successfully to ${REGISTRY}!"
                    } catch (Exception e) {
                        echo "❌ Docker push failed: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo "☸️ Deploying to Kubernetes (${COLOR} environment)..."
                script {
                    try {
                        sh """
                            echo "Current kubectl context:"
                            kubectl config current-context || echo "No kubectl context set"
                            
                            echo "Updating deployment-${COLOR}.yaml with new image..."
                            cd app/k8s
                            
                            # Update the deployment with new image and build number
                            sed -i.bak 's|image: myapp:latest|image: ${IMAGE}|g' deployment-${COLOR}.yaml
                            sed -i.bak 's|BUILD_NUMBER.*|BUILD_NUMBER\\n          value: "${BUILD_NUMBER}"|g' deployment-${COLOR}.yaml
                            
                            echo "Applying ${COLOR} deployment..."
                            kubectl apply -f deployment-${COLOR}.yaml --record
                            
                            echo "Current deployments:"
                            kubectl get deployments -l app=myapp
                        """
                        echo "✅ Deployment applied successfully!"
                    } catch (Exception e) {
                        echo "❌ Kubernetes deployment failed: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
        
        stage('Wait for Rollout') {
            steps {
                echo "⏳ Waiting for rollout to complete..."
                script {
                    try {
                        timeout(time: 5, unit: 'MINUTES') {
                            sh """
                                echo "Checking rollout status for myapp-${COLOR}..."
                                kubectl rollout status deployment/myapp-${COLOR} --timeout=300s
                                
                                echo "Deployment status:"
                                kubectl get deployment myapp-${COLOR} -o wide
                                
                                echo "Pod status:"
                                kubectl get pods -l app=myapp,color=${COLOR}
                                
                                echo "Waiting for pods to be ready..."
                                kubectl wait --for=condition=ready pod -l app=myapp,color=${COLOR} --timeout=300s
                            """
                        }
                        echo "✅ Rollout completed successfully!"
                    } catch (Exception e) {
                        echo "❌ Rollout failed or timed out: ${e.getMessage()}"
                        echo "🔄 Attempting automatic rollback..."
                        
                        // Automatic rollback on deployment failure
                        sh """
                            echo "Rolling back deployment..."
                            kubectl rollout undo deployment/myapp-${COLOR}
                            kubectl rollout status deployment/myapp-${COLOR} --timeout=180s
                        """
                        
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo "🏥 Performing health check on ${COLOR} deployment..."
                script {
                    try {
                        sh """
                            echo "Getting service information..."
                            kubectl get service myapp-service -o wide
                            
                            echo "Testing health endpoint on ${COLOR} pods..."
                            PODS=\$(kubectl get pods -l app=myapp,color=${COLOR} -o jsonpath='{.items[*].metadata.name}')
                            
                            for pod in \$PODS; do
                                echo "Testing health check for pod: \$pod"
                                kubectl exec \$pod -- curl -f http://localhost:8080/health || exit 1
                            done
                        """
                        echo "✅ Health check passed!"
                    } catch (Exception e) {
                        echo "❌ Health check failed: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
        
        stage('Manual Approval') {
            steps {
                script {
                    def previousColor = (COLOR == 'blue') ? 'green' : 'blue'
                    echo "🎯 Ready to switch traffic to ${COLOR} deployment"
                    echo "📊 Current service selector points to: ${previousColor}"
                    echo "🔄 After approval, traffic will switch to: ${COLOR}"
                    
                    // Show current deployment status
                    sh """
                        echo "=== DEPLOYMENT SUMMARY ==="
                        echo "Current deployments:"
                        kubectl get deployments -l app=myapp -o wide
                        
                        echo "Current service selector:"
                        kubectl get service myapp-service -o jsonpath='{.spec.selector}' | jq .
                        
                        echo "Pods ready for ${COLOR}:"
                        kubectl get pods -l app=myapp,color=${COLOR}
                    """
                    
                    def previousColor = (COLOR == 'blue') ? 'green' : 'blue'
                    timeout(time: 10, unit: 'MINUTES') {
                        input message: """
                        🚦 Ready to switch traffic to ${COLOR}?
                        
                        Current Status:
                        • ${COLOR} deployment is ready and healthy
                        • Service currently points to: ${previousColor}
                        
                        Click 'Proceed' to switch traffic to ${COLOR}
                        """, 
                        ok: 'Proceed with Traffic Switch'
                    }
                }
            }
        }
        
        stage('Switch Traffic') {
            steps {
                script {
                    def previousColor = (COLOR == 'blue') ? 'green' : 'blue'
                    echo "🔄 Switching traffic from ${previousColor} to ${COLOR}..."
                    try {
                        sh """
                            echo "Current service selector:"
                            kubectl get service myapp-service -o jsonpath='{.spec.selector}'
                            
                            echo "Patching service to point to ${COLOR}..."
                            kubectl patch service myapp-service -p '{"spec":{"selector":{"color":"${COLOR}"}}}'
                            
                            echo "Verifying service update..."
                            kubectl get service myapp-service -o jsonpath='{.spec.selector}' | jq .
                            
                            echo "Service endpoints:"
                            kubectl get endpoints myapp-service
                        """
                        echo "✅ Traffic successfully switched to ${COLOR}!"
                    } catch (Exception e) {
                        echo "❌ Traffic switch failed: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
            }
        }
        
        stage('Cleanup Old Deployment') {
            when {
                expression { return !params.SKIP_TESTS }
            }
            steps {
                script {
                    def previousColor = (COLOR == 'blue') ? 'green' : 'blue'
                    timeout(time: 2, unit: 'MINUTES') {
                        try {
                            input message: """
                            🧹 Cleanup old ${previousColor} deployment?
                            
                            Current Status:
                            • Traffic is now on ${COLOR}
                            • ${previousColor} deployment is still running
                            
                            Click 'Proceed' to remove ${previousColor} deployment
                            """, 
                            ok: 'Cleanup Old Deployment'
                            
                            echo "🧹 Cleaning up old ${previousColor} deployment..."
                            sh """
                                echo "Scaling down ${previousColor} deployment..."
                                kubectl scale deployment myapp-${previousColor} --replicas=0
                                
                                echo "Remaining deployments:"
                                kubectl get deployments -l app=myapp
                            """
                            echo "✅ Old deployment cleaned up!"
                            
                        } catch (Exception e) {
                            echo "⏭️ Cleanup skipped or timed out - keeping ${previousColor} deployment for manual cleanup"
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "🏁 Pipeline completed!"
            script {
                sh """
                    echo "=== FINAL STATUS ==="
                    kubectl get deployments -l app=myapp -o wide || echo "No deployments found"
                    kubectl get service myapp-service -o wide || echo "No service found"
                    kubectl get pods -l app=myapp || echo "No pods found"
                """
            }
        }
        
        success {
            echo "🎉 Deployment successful!"
            script {
                sh """
                    echo "✅ SUCCESS: ${COLOR} deployment completed successfully"
                    echo "🌐 Application URL: http://\$(kubectl get service myapp-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo 'pending')"
                    echo "🎨 Active Color: ${COLOR}"
                    echo "📦 Image: ${IMAGE}"
                """
            }
        }
        
        failure {
            echo "❌ Deployment failed!"
            script {
                try {
                    def previousColor = (COLOR == 'blue') ? 'green' : 'blue'
                    echo "🔄 Attempting automatic rollback to ${previousColor}..."
                    sh """
                        echo "Rolling back service to ${previousColor}..."
                        kubectl patch service myapp-service -p '{"spec":{"selector":{"color":"${previousColor}"}}}'
                        
                        echo "Checking ${previousColor} deployment status..."
                        kubectl get deployment myapp-${previousColor} || echo "${previousColor} deployment not found"
                        
                        echo "Service rolled back to ${previousColor}"
                        kubectl get service myapp-service -o jsonpath='{.spec.selector}'
                    """
                    echo "✅ Automatic rollback to ${previousColor} completed"
                } catch (Exception rollbackError) {
                    echo "❌ Automatic rollback failed: ${rollbackError.getMessage()}"
                    echo "🚨 Manual intervention required!"
                }
            }
        }
        
        cleanup {
            echo "🧹 Cleaning up workspace..."
            // Clean up local Docker images to save space
            sh """
                docker rmi ${IMAGE} || echo "Image cleanup skipped"
                docker system prune -f || echo "Docker cleanup skipped"
            """
        }
    }
}
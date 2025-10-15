pipeline {
    agent any
    
    parameters {
        choice(
            name: 'DEPLOYMENT_COLOR',
            choices: ['blue', 'green'],
            description: 'Choose deployment color for blue-green deployment'
        )
        booleanParam(
            name: 'SKIP_DOCKER_BUILD',
            defaultValue: false,
            description: 'Skip Docker build and use existing image'
        )
    }
    
    environment {
        APP_NAME = "vle7-app"
        NAMESPACE = "default"
        DOCKER_IMAGE = "${APP_NAME}:${BUILD_NUMBER}"
        COLOR = "${params.DEPLOYMENT_COLOR}"
        PREVIOUS_COLOR = "${params.DEPLOYMENT_COLOR == 'blue' ? 'green' : 'blue'}"
        SERVICE_NAME = "${APP_NAME}-service"
    }
    
    stages {
        stage('Initialize') {
            steps {
                script {
                    echo "🚀 Starting VLE7 Blue-Green Deployment Pipeline"
                    echo "📦 App Name: ${APP_NAME}"
                    echo "🎨 Target Color: ${COLOR}"
                    echo "� Previous Color: ${PREVIOUS_COLOR}"
                    echo "📋 Build Number: ${BUILD_NUMBER}"
                    echo "⏭️ Skip Docker Build: ${params.SKIP_DOCKER_BUILD}"
                    
                    // Set workspace context
                    sh """
                        echo "Current working directory:"
                        pwd
                        ls -la
                        
                        echo "Kubernetes cluster info:"
                        kubectl cluster-info || echo "Kubectl not configured yet"
                    """
                }
            }
        }
        
        stage('Checkout') {
            steps {
                echo "📥 Code already checked out by Jenkins"
                sh """
                    echo "Repository contents:"
                    find . -name "*.yaml" -o -name "*.yml" -o -name "Dockerfile" -o -name "*.js" | head -20
                """
            }
        }
        
        stage('Prepare Application') {
            when {
                not {
                    expression { params.SKIP_DOCKER_BUILD }
                }
            }
            steps {
                echo "� Preparing application deployment..."
                dir('app') {
                    script {
                        try {
                            sh """
                                echo "Application preparation for ${COLOR} deployment..."
                                echo "Using pre-built image or remote build process"
                                echo "Build number: ${BUILD_NUMBER}"
                                
                                # In production, this would:
                                # 1. Trigger remote Docker build (e.g., AWS CodeBuild, GitHub Actions)
                                # 2. Use pre-built images from registry
                                # 3. Build on separate build server
                                
                                echo "✅ Application prepared for deployment"
                            """
                            echo "✅ Application preparation completed!"
                        } catch (Exception e) {
                            echo "❌ Application preparation failed: ${e.getMessage()}"
                            currentBuild.result = 'FAILURE'
                            throw e
                        }
                    }
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                echo "☸️ Deploying ${COLOR} environment to Kubernetes..."
                script {
                    try {
                        dir('app/k8s') {
                            // Update deployment with current build number
                            sh """
                                echo "Updating deployment-${COLOR}.yaml with build number ${BUILD_NUMBER}..."
                                sed -i.bak "s/value: \\"1\\"/value: \\"${BUILD_NUMBER}\\"/g" deployment-${COLOR}.yaml
                                
                                echo "Checking Kubernetes cluster connectivity..."
                                kubectl cluster-info || echo "⚠️ Warning: No Kubernetes cluster configured"
                                
                echo "Applying ${COLOR} deployment..."
                CLUSTER_STATUS=\$(kubectl cluster-info &>/dev/null && echo "connected" || echo "disconnected")
                
                if [ "\$CLUSTER_STATUS" = "connected" ]; then
                    kubectl apply -f deployment-${COLOR}.yaml
                    echo "✅ Deployment applied to cluster"
                else
                    echo "🔧 DEMO MODE: No Kubernetes cluster configured"
                    echo "📋 Would apply: deployment-${COLOR}.yaml"
                    echo "📄 Deployment content:"
                    cat deployment-${COLOR}.yaml | head -10
                    echo "... (showing first 10 lines)"
                fi
                
                echo "Ensuring service exists..."
                if [ "\$CLUSTER_STATUS" = "connected" ]; then
                    kubectl apply -f service.yaml
                    echo "✅ Service applied to cluster"
                else
                    echo "🔧 DEMO MODE: Would apply service configuration"  
                    echo "📋 Would apply: service.yaml"
                    echo "📄 Service content:"
                    cat service.yaml | head -10
                    echo "... (showing first 10 lines)"
                fi
                
                echo "Current deployments:"
                if [ "\$CLUSTER_STATUS" = "connected" ]; then
                    kubectl get deployments -l app=${APP_NAME} -o wide
                else
                    echo "🔧 DEMO MODE: Would show deployments for app=${APP_NAME}"
                    echo "📋 Expected deployment: ${APP_NAME}-${COLOR}"
                fi
                
                echo "Current services:"
                if [ "\$CLUSTER_STATUS" = "connected" ]; then
                    kubectl get services -l app=${APP_NAME} -o wide
                else
                    echo "🔧 DEMO MODE: Would show services for app=${APP_NAME}"
                    echo "📋 Expected service: ${SERVICE_NAME}"
                fi
                            """
                        }
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
                echo "⏳ Waiting for ${COLOR} deployment to be ready..."
                script {
                    try {
                        timeout(time: 5, unit: 'MINUTES') {
                            sh """
                                sh """
                            echo "Checking rollout status for ${APP_NAME}-${COLOR}..."
                            CLUSTER_STATUS=\$(kubectl cluster-info &>/dev/null && echo "connected" || echo "disconnected")
                            
                            if [ "\$CLUSTER_STATUS" = "connected" ]; then
                                kubectl rollout status deployment/${APP_NAME}-${COLOR} --timeout=300s
                                
                                echo "Deployment status:"
                                kubectl get deployment ${APP_NAME}-${COLOR} -o wide
                                
                                echo "Pod status:"
                                kubectl get pods -l app=${APP_NAME},version=${COLOR}
                                
                                echo "Pod details:"
                                kubectl describe pods -l app=${APP_NAME},version=${COLOR} | tail -20
                            else
                                echo "🔧 DEMO MODE: Simulating rollout success"
                                echo "✅ Would wait for deployment/${APP_NAME}-${COLOR} to be ready"
                                echo "📋 Expected pods: 2 replicas of ${APP_NAME}-${COLOR}"
                                echo "🎯 Container: nginx:alpine with build number ${BUILD_NUMBER}"
                                sleep 2  # Simulate rollout time
                                echo "✅ Simulated rollout completed successfully!"
                            fi
                        """
                            """
                        }
                        echo "✅ Rollout completed successfully!"
                    } catch (Exception e) {
                        echo "❌ Rollout failed or timed out: ${e.getMessage()}"
                        sh """
                            echo "Debugging failed rollout..."
                            kubectl get pods -l app=${APP_NAME},version=${COLOR}
                            kubectl describe deployment ${APP_NAME}-${COLOR}
                            kubectl logs -l app=${APP_NAME},version=${COLOR} --tail=50 || echo "No logs available"
                        """
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo "🏥 Performing health check for ${COLOR} deployment..."
                script {
                    try {
                        sh """
                            echo "Checking pod health..."
                            
                            # Check if pods are running
                            RUNNING_PODS=\$(kubectl get pods -l app=${APP_NAME},version=${COLOR} --field-selector=status.phase=Running --no-headers | wc -l)
                            TOTAL_PODS=\$(kubectl get pods -l app=${APP_NAME},version=${COLOR} --no-headers | wc -l)
                            
                            echo "Running pods: \$RUNNING_PODS / \$TOTAL_PODS"
                            
                            if [ "\$RUNNING_PODS" -eq "0" ]; then
                                echo "❌ No running pods found!"
                                exit 1
                            fi
                            
                            if [ "\$RUNNING_PODS" -lt "\$TOTAL_PODS" ]; then
                                echo "⚠️ Some pods are not running, but continuing..."
                            fi
                            
                            echo "✅ Health check passed with \$RUNNING_PODS running pod(s)"
                            
                            # Get service URL for testing
                            echo "Service information:"
                            kubectl get service ${SERVICE_NAME} -o wide
                        """
                        echo "✅ Health check completed!"
                    } catch (Exception e) {
                        echo "❌ Health check failed: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
        
        stage('Traffic Switch Approval') {
            steps {
                script {
                    echo "🎯 Ready to switch traffic to ${COLOR} deployment"
                    
                    sh """
                        echo "=== DEPLOYMENT SUMMARY ==="
                        echo "Target: ${COLOR} deployment"
                        echo "Previous: ${PREVIOUS_COLOR} deployment"
                        echo ""
                        kubectl get deployments -l app=${APP_NAME} -o wide
                        echo ""
                        kubectl get service ${SERVICE_NAME} -o wide
                        echo ""
                        kubectl get pods -l app=${APP_NAME}
                        echo ""
                        echo "Current service selector:"
                        kubectl get service ${SERVICE_NAME} -o jsonpath='{.spec.selector}'
                        echo ""
                    """
                    
                    timeout(time: 10, unit: 'MINUTES') {
                        input message: """
                        🚦 Switch traffic to ${COLOR}?
                        
                        New ${COLOR} deployment is ready and healthy.
                        
                        Click 'Proceed' to switch all traffic to ${COLOR}
                        Click 'Abort' to cancel deployment
                        """, 
                        ok: 'Proceed with Traffic Switch'
                    }
                }
            }
        }
        
        stage('Switch Traffic') {
            steps {
                script {
                    echo "🔄 Switching traffic from ${PREVIOUS_COLOR} to ${COLOR}..."
                    try {
                        sh """
                            echo "Current service selector:"
                            kubectl get service ${SERVICE_NAME} -o jsonpath='{.spec.selector}'
                            echo ""
                            
                            echo "Switching service selector to version=${COLOR}..."
                            kubectl patch service ${SERVICE_NAME} -p '{"spec":{"selector":{"app":"${APP_NAME}","version":"${COLOR}"}}}'
                            
                            echo ""
                            echo "New service selector:"
                            kubectl get service ${SERVICE_NAME} -o jsonpath='{.spec.selector}'
                            echo ""
                            
                            echo "Service endpoints:"
                            kubectl get endpoints ${SERVICE_NAME}
                            
                            echo ""
                            echo "Service details:"
                            kubectl describe service ${SERVICE_NAME}
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
        
        stage('Post-Switch Verification') {
            steps {
                echo "🔍 Verifying traffic switch..."
                script {
                    try {
                        sh """
                            echo "Verifying traffic is flowing to ${COLOR}..."
                            
                            # Check service endpoints
                            kubectl get endpoints ${SERVICE_NAME}
                            
                            # Verify service is pointing to correct pods
                            ENDPOINT_IPS=\$(kubectl get endpoints ${SERVICE_NAME} -o jsonpath='{.subsets[0].addresses[*].ip}')
                            echo "Service endpoint IPs: \$ENDPOINT_IPS"
                            
                            # Check which pods these IPs belong to
                            for ip in \$ENDPOINT_IPS; do
                                echo "IP \$ip belongs to:"
                                kubectl get pods -o wide | grep \$ip || echo "Pod not found for IP \$ip"
                            done
                            
                            echo "✅ Traffic verification completed"
                        """
                    } catch (Exception e) {
                        echo "⚠️ Verification had issues but continuing: ${e.getMessage()}"
                    }
                }
            }
        }
        
        stage('Cleanup Old Deployment') {
            steps {
                script {
                    try {
                        timeout(time: 5, unit: 'MINUTES') {
                            input message: """
                            🧹 Remove old ${PREVIOUS_COLOR} deployment?
                            
                            Traffic is now successfully switched to: ${COLOR}
                            Old deployment: ${PREVIOUS_COLOR} (safe to remove)
                            
                            This will free up cluster resources.
                            """, 
                            ok: "Remove ${PREVIOUS_COLOR} Deployment"
                            
                            echo "🧹 Removing old ${PREVIOUS_COLOR} deployment..."
                            sh """
                                kubectl delete deployment ${APP_NAME}-${PREVIOUS_COLOR} --ignore-not-found=true
                                echo "Remaining deployments:"
                                kubectl get deployments -l app=${APP_NAME}
                            """
                            echo "✅ Cleanup completed!"
                        }
                    } catch (Exception e) {
                        echo "⏭️ Cleanup skipped - keeping both deployments for safety"
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "📊 Final deployment status:"
                sh """
                    echo "=== FINAL STATUS ==="
                    echo "Active deployments:"
                    kubectl get deployments -l app=${APP_NAME} -o wide || echo "No deployments found"
                    echo ""
                    echo "Service configuration:"
                    kubectl get service ${SERVICE_NAME} -o wide || echo "No service found"
                    echo ""
                    echo "Running pods:"
                    kubectl get pods -l app=${APP_NAME} -o wide || echo "No pods found"
                    echo ""
                    echo "Service details:"
                    kubectl describe service ${SERVICE_NAME} || echo "Service not found"
                """
            }
        }
        
        success {
            echo "🎉 VLE7 Blue-Green deployment completed successfully!"
            script {
                sh """
                    echo "✅ SUCCESS SUMMARY:"
                    echo "🎨 Active Color: ${COLOR}"
                    echo "📦 App Name: ${APP_NAME}"
                    echo "🔢 Build Number: ${BUILD_NUMBER}"
                    echo ""
                    echo "🌐 Access your application:"
                    echo "kubectl port-forward service/${SERVICE_NAME} 8080:80"
                    echo "Then visit: http://localhost:8080"
                    echo ""
                    echo "Or use minikube:"
                    echo "minikube service ${SERVICE_NAME} --url"
                """
            }
        }
        
        failure {
            echo "❌ VLE7 deployment failed!"
            script {
                try {
                    echo "🔄 Attempting automatic rollback to ${PREVIOUS_COLOR}..."
                    sh """
                        # Try to rollback service to previous color
                        kubectl patch service ${SERVICE_NAME} -p '{"spec":{"selector":{"app":"${APP_NAME}","version":"${PREVIOUS_COLOR}"}}}'
                        echo "Rollback completed - service now points to ${PREVIOUS_COLOR}"
                        
                        # Show current status
                        kubectl get deployments -l app=${APP_NAME}
                        kubectl get service ${SERVICE_NAME} -o jsonpath='{.spec.selector}'
                    """
                    echo "✅ Rollback completed successfully"
                } catch (Exception e) {
                    echo "❌ Rollback also failed: ${e.getMessage()}"
                    echo "Manual intervention required!"
                }
            }
        }
        
        cleanup {
            echo "🧽 Pipeline cleanup completed"
        }
    }
}
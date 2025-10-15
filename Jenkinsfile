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
                    echo "📋 Build Number: ${BUILD_NUMBER}"
                    echo "⏭️ Skip Docker Build: ${params.SKIP_DOCKER_BUILD}"

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

        stage('Deploy Application') {
            steps {
                echo "☸️ Deploying ${COLOR} environment to Kubernetes..."
                script {
                    dir('app/k8s') {
                        sh """
                            echo "Updating deployment-${COLOR}.yaml with build number ${BUILD_NUMBER}..."
                            sed -i.bak "s/value: \\"1\\"/value: \\"${BUILD_NUMBER}\\"/g" deployment-${COLOR}.yaml

                            echo "Checking Kubernetes cluster connectivity..."
                            if kubectl cluster-info &>/dev/null; then
                                CLUSTER_STATUS="connected"
                            else
                                CLUSTER_STATUS="disconnected"
                            fi

                            echo "Cluster status: \$CLUSTER_STATUS"

                            if [ "\$CLUSTER_STATUS" = "connected" ]; then
                                kubectl apply -f deployment-${COLOR}.yaml
                                kubectl apply -f service.yaml
                                echo "✅ Deployment and service applied"
                            else
                                echo "🔧 DEMO MODE: Would apply deployment and service"
                                echo "Deployment content (first 10 lines):"
                                head -10 deployment-${COLOR}.yaml
                                echo "Service content (first 10 lines):"
                                head -10 service.yaml
                            fi

                            echo "Current deployments:"
                            if [ "\$CLUSTER_STATUS" = "connected" ]; then
                                kubectl get deployments -l app=${APP_NAME} -o wide
                            else
                                echo "🔧 DEMO MODE: Deployment ${APP_NAME}-${COLOR}"
                            fi
                        """
                    }
                }
            }
        }

        stage('Wait for Rollout') {
            steps {
                echo "⏳ Waiting for ${COLOR} deployment to be ready..."
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        sh """
                            if kubectl cluster-info &>/dev/null; then
                                kubectl rollout status deployment/${APP_NAME}-${COLOR} --timeout=300s
                                kubectl get deployment ${APP_NAME}-${COLOR} -o wide
                                kubectl get pods -l app=${APP_NAME},version=${COLOR}
                            else
                                echo "🔧 DEMO MODE: Simulating rollout"
                                sleep 2
                                echo "✅ Simulated rollout completed!"
                            fi
                        """
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    sh """
                        RUNNING_PODS=\$(kubectl get pods -l app=${APP_NAME},version=${COLOR} --field-selector=status.phase=Running --no-headers | wc -l)
                        TOTAL_PODS=\$(kubectl get pods -l app=${APP_NAME},version=${COLOR} --no-headers | wc -l)
                        echo "Running pods: \$RUNNING_PODS / \$TOTAL_PODS"
                        if [ "\$RUNNING_PODS" -eq "0" ]; then
                            echo "❌ No running pods found!"
                            exit 1
                        fi
                    """
                }
            }
        }

        stage('Traffic Switch') {
            steps {
                script {
                    sh """
                        echo "Switching service selector to version=${COLOR}..."
                        kubectl patch service ${SERVICE_NAME} -p '{"spec":{"selector":{"app":"${APP_NAME}","version":"${COLOR}"}}}'
                        echo "✅ Traffic switched"
                    """
                }
            }
        }

        stage('Cleanup Old Deployment') {
            steps {
                script {
                    sh """
                        kubectl delete deployment ${APP_NAME}-${PREVIOUS_COLOR} --ignore-not-found=true
                        kubectl get deployments -l app=${APP_NAME}
                    """
                }
            }
        }

        stage('Debug Kubernetes') {
            steps {
                sh '''
                echo "KUBECONFIG: $KUBECONFIG"
                kubectl cluster-info
                kubectl get nodes
                '''
            }
        }
    }

    post {
        always {
            echo "📊 Final deployment status:"
            sh """
                kubectl get deployments -l app=${APP_NAME} -o wide || echo "No deployments found"
                kubectl get service ${SERVICE_NAME} -o wide || echo "No service found"
                kubectl get pods -l app=${APP_NAME} -o wide || echo "No pods found"
            """
        }
        success {
            echo "🎉 Deployment completed successfully!"
        }
        failure {
            echo "❌ Deployment failed!"
        }
    }
}

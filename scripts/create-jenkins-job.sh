#!/bin/bash

# Jenkins Pipeline Job Creation Script
# This script creates the VLE7 Blue-Green Pipeline job in Jenkins

set -e

# Configuration
JENKINS_URL="http://localhost:8080"
JOB_NAME="vle7-app-pipeline"
GITHUB_REPO="https://github.com/YasinSaleem/vle7.git"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"
}

# Get Jenkins admin password
get_jenkins_password() {
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        cat /var/lib/jenkins/secrets/initialAdminPassword
    else
        echo "admin"  # Default fallback
    fi
}

# Wait for Jenkins to be ready
wait_for_jenkins() {
    log "Waiting for Jenkins to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "${JENKINS_URL}/login" > /dev/null 2>&1; then
            log "Jenkins is ready!"
            return 0
        fi
        
        echo "Attempt $attempt/$max_attempts: Jenkins not ready yet..."
        sleep 10
        ((attempt++))
    done
    
    error "Jenkins failed to become ready after $max_attempts attempts"
    return 1
}

# Create Jenkins pipeline job using XML configuration
create_pipeline_job() {
    log "Creating Jenkins pipeline job: $JOB_NAME"
    
    local admin_password=$(get_jenkins_password)
    
    # Create job XML configuration
    cat > /tmp/job-config.xml << EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>VLE7 Blue-Green Deployment Pipeline - Automated Blue/Green deployment with Docker and Kubernetes</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.plugins.jira.JiraProjectProperty plugin="jira@3.7"/>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.plugins.BitBucketTrigger plugin="bitbucket@1.1.5">
          <spec></spec>
        </com.cloudbees.jenkins.plugins.BitBucketTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.ChoiceParameterDefinition>
          <name>DEPLOYMENT_COLOR</name>
          <description>Choose deployment color for blue-green deployment</description>
          <choices class="java.util.Arrays\$ArrayList">
            <a class="string-array">
              <string>blue</string>
              <string>green</string>
            </a>
          </choices>
        </hudson.model.ChoiceParameterDefinition>
        <hudson.model.BooleanParameterDefinition>
          <name>SKIP_DOCKER_BUILD</name>
          <description>Skip Docker build and use existing image</description>
          <defaultValue>false</defaultValue>
        </hudson.model.BooleanParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.87">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>${GITHUB_REPO}</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

    # Create the job using Jenkins CLI
    local jenkins_cli="/var/lib/jenkins/jenkins-cli.jar"
    
    # Download Jenkins CLI if not exists
    if [ ! -f "$jenkins_cli" ]; then
        wget -q -O "$jenkins_cli" "${JENKINS_URL}/jnlpJars/jenkins-cli.jar"
    fi
    
    # Create the job
    if java -jar "$jenkins_cli" -s "$JENKINS_URL" -auth "admin:$admin_password" create-job "$JOB_NAME" < /tmp/job-config.xml; then
        log "✅ Pipeline job '$JOB_NAME' created successfully!"
    else
        warn "Job creation failed or job already exists"
        # Try to update existing job
        if java -jar "$jenkins_cli" -s "$JENKINS_URL" -auth "admin:$admin_password" update-job "$JOB_NAME" < /tmp/job-config.xml; then
            log "✅ Pipeline job '$JOB_NAME' updated successfully!"
        else
            error "Failed to create or update job"
            return 1
        fi
    fi
    
    # Clean up
    rm -f /tmp/job-config.xml
}

# Display final instructions
show_instructions() {
    local admin_password=$(get_jenkins_password)
    
    log "🎉 Jenkins pipeline setup complete!"
    echo ""
    echo "========================================"
    echo "    Jenkins Access Information"
    echo "========================================"
    echo "🌐 URL: ${JENKINS_URL}"
    echo "👤 Username: admin"
    echo "🔐 Password: $admin_password"
    echo ""
    echo "📋 Pipeline Job: $JOB_NAME"
    echo "🔗 Job URL: ${JENKINS_URL}/job/${JOB_NAME}/"
    echo ""
    echo "🎯 Next Steps:"
    echo "1. Access Jenkins at: ${JENKINS_URL}"
    echo "2. Login with admin credentials above"
    echo "3. Navigate to: ${JOB_NAME}"
    echo "4. Click 'Build with Parameters' to test"
    echo ""
    echo "🔗 GitHub Webhook URL:"
    echo "   ${JENKINS_URL}/github-webhook/"
    echo ""
    echo "✅ Setup Complete!"
    echo "========================================"
}

# Main execution
main() {
    log "🚀 Creating Jenkins Pipeline Job for VLE7"
    
    if ! wait_for_jenkins; then
        error "Jenkins setup failed - cannot proceed"
        exit 1
    fi
    
    if ! create_pipeline_job; then
        error "Pipeline job creation failed"
        exit 1
    fi
    
    show_instructions
    log "✅ Jenkins pipeline job setup completed successfully!"
}

# Run main function
main "$@"
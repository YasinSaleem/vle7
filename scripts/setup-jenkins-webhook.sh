#!/bin/bash

# Jenkins Webhook Setup Script
# This script helps set up the Jenkins pipeline job for GitHub webhooks

JENKINS_URL="http://localhost:8080"
JOB_NAME="vle7-blue-green-pipeline"
GITHUB_REPO="https://github.com/YasinSaleem/vle7.git"

echo "=== Jenkins Pipeline Job Setup ==="
echo "Jenkins URL: $JENKINS_URL"
echo "Job Name: $JOB_NAME"
echo "GitHub Repo: $GITHUB_REPO"
echo ""

# Create job configuration XML
cat > /tmp/job-config.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1400.v7fd111b_ec82f">
  <actions/>
  <description>Blue-Green Deployment Pipeline for VLE7 Application</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty plugin="github@1.37.3.1">
      <projectUrl>https://github.com/YasinSaleem/vle7/</projectUrl>
      <displayName></displayName>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.37.3.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3803.v1a_f77ffcc773">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.2.2">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/YasinSaleem/vle7.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

echo "Job configuration created at /tmp/job-config.xml"
echo ""
echo "=== Manual Setup Instructions ==="
echo ""
echo "1. In Jenkins Web UI (http://54.81.93.16:8080):"
echo "   - Click 'New Item'"
echo "   - Name: $JOB_NAME"
echo "   - Type: Pipeline"
echo "   - Click OK"
echo ""
echo "2. Configure the job:"
echo "   - General: Check 'GitHub project'"
echo "   - Project URL: https://github.com/YasinSaleem/vle7"
echo "   - Build Triggers: Check 'GitHub hook trigger for GITScm polling'"
echo "   - Pipeline: 'Pipeline script from SCM'"
echo "   - SCM: Git"
echo "   - Repository URL: $GITHUB_REPO"
echo "   - Branch: */main"
echo "   - Script Path: Jenkinsfile"
echo "   - Save"
echo ""
echo "3. GitHub Webhook Setup:"
echo "   - Go to: https://github.com/YasinSaleem/vle7/settings/hooks"
echo "   - Add webhook:"
echo "   - Payload URL: http://54.81.93.16:8080/github-webhook/"
echo "   - Content type: application/json"
echo "   - Events: Just the push event"
echo "   - Active: Yes"
echo ""
echo "=== Webhook Payload URL ==="
echo "http://54.81.93.16:8080/github-webhook/"
echo ""
echo "=== Test Webhook ==="
echo "After setup, push to your repo and check:"
echo "- Jenkins job should trigger automatically"
echo "- Check Jenkins build history"
echo "- Verify blue-green deployment works"
echo ""
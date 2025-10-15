#!/bin/bash

# Jenkins Build Trigger Fix Script
# This script helps resolve the "No changes" issue after a failed build

echo "🔧 Jenkins Build Trigger Fix"
echo "==========================="

echo "The issue: Jenkins thinks there are 'No changes' because the first build failed"
echo "Solution: We need to either manually trigger a build or reset the SCM state"
echo ""

echo "Option 1: Manual Web Trigger (Recommended)"
echo "1. Go to: http://54.81.93.16:8080/job/vle7-blue-green-pipeline/"
echo "2. Click 'Build with Parameters'"
echo "3. Select DEPLOYMENT_COLOR: blue (or green)"
echo "4. Keep SKIP_DOCKER_BUILD: false" 
echo "5. Click 'Build'"
echo ""

echo "Option 2: Reset SCM Polling"
echo "1. Go to: http://54.81.93.16:8080/job/vle7-blue-green-pipeline/configure"
echo "2. Scroll to 'Build Triggers'"
echo "3. Uncheck 'GitHub hook trigger for GITScm polling'"
echo "4. Save"
echo "5. Go back to configure"
echo "6. Re-check 'GitHub hook trigger for GITScm polling'"
echo "7. Save"
echo ""

echo "Option 3: Force SCM Update (via Jenkins Script Console)"
echo "1. Go to: http://54.81.93.16:8080/script"
echo "2. Run this Groovy script:"
echo ""
cat << 'GROOVY'
// Reset SCM polling for vle7-blue-green-pipeline
def job = Jenkins.instance.getItem('vle7-blue-green-pipeline')
if (job != null) {
    // Clear the polling log
    job.pollingBaseline = null
    job.save()
    println "SCM polling reset for vle7-blue-green-pipeline"
} else {
    println "Job not found"
}
GROOVY
echo ""

echo "After applying any of these solutions, push a small change to test:"
echo "echo '# Test webhook fix' >> README.md"
echo "git add README.md"
echo "git commit -m 'Test webhook after Jenkins fix'"
echo "git push origin main"

echo ""
echo "🎯 Expected Result:"
echo "- Webhook triggers Jenkins"
echo "- New build #2 starts"
echo "- Pipeline executes successfully"
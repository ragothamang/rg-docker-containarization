#!/bin/bash
set -e

echo "🚀 Starting Jenkins..."

export JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# 🔥 Remove setup wizard password
rm -f /var/jenkins_home/secrets/initialAdminPassword

# ✅ Ensure required directories exist
mkdir -p /var/jenkins_home/workspace/automation-suite

# 🚀 Start Jenkins in the background
exec /usr/local/bin/jenkins.sh &

# ⏳ Wait for Jenkins
echo "⏳ Waiting for Jenkins to be fully ready..."
until curl -sSf http://localhost:8080/login >/dev/null; do
  echo "🔄 Jenkins is still starting... Retrying in 10s..."
  sleep 10
done
echo "✅ Jenkins is fully up and running!"

# 📂 Ensure the workspace directory exists
mkdir -p /var/jenkins_home/workspace/automation-suite

# ✅ Ensure Jenkins CLI is installed
JENKINS_CLI="/var/jenkins_home/jenkins-cli.jar"
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASS="admin"

# ⏳ Wait for Jenkins CLI
echo "⏳ Waiting for Jenkins CLI..."
until curl -sSf "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" >/dev/null; do
  echo "🔄 Jenkins CLI not available yet. Retrying in 10s..."
  sleep 10
done
echo "✅ Jenkins CLI is available!"

# 📥 Download Jenkins CLI if not already downloaded
if [ ! -f "$JENKINS_CLI" ]; then
  wget "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -O "$JENKINS_CLI"
fi

# 🚀 Create Pipeline Job (if not exists)
echo "🔄 Checking if Jenkins pipeline job exists..."
JOB_NAME="automation-pipeline"

if ! java -jar "$JENKINS_CLI" -auth "$JENKINS_USER:$JENKINS_PASS" -s "$JENKINS_URL" get-job "$JOB_NAME" > /dev/null 2>&1; then
  echo "🚀 Creating Jenkins pipeline job: $JOB_NAME"

  cat <<EOF > /var/jenkins_home/automation-pipeline.xml
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Automation test pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps">
    <script><![CDATA[$(cat /var/jenkins_home/Jenkinsfile)]]></script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

  # Create the job using Jenkins CLI
 # java -jar "$JENKINS_CLI" -auth "$JENKINS_USER:$JENKINS_PASS" -s "$JENKINS_URL" create-job "$JOB_NAME" < /var/jenkins_home/automation-pipeline.xml
  #echo "✅ Jenkins pipeline job created: $JOB_NAME"
#else
 # echo "✅ Jenkins pipeline job already exists: $JOB_NAME"
#fi

# 🚀 Trigger Pipeline Job
#echo "▶️ Triggering Jenkins pipeline job..."
#java -jar "$JENKINS_CLI" -auth "$JENKINS_USER:$JENKINS_PASS" -s "$JENKINS_URL" build "$JOB_NAME" -f
#echo "✅ Jenkins pipeline job triggered successfully!"

# Keep container running
wait

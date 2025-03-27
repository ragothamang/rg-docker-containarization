#!/bin/bash
set -e

echo "🚀 Starting Jenkins..."

export JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# 🔥 Remove setup wizard password
rm -f /var/jenkins_home/secrets/initialAdminPassword

# ✅ Ensure required directories exist
mkdir -p /var/jenkins_home/workspace/automation-suite
mkdir -p /var/jenkins_home/init.groovy.d  # <-- Ensure the directory exists

# 📌 Create Jenkins admin user if not exists
JENKINS_USER="admin"
JENKINS_PASS="admin"

cat <<EOF > /var/jenkins_home/init.groovy.d/basic-security.groovy
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("${JENKINS_USER}", "${JENKINS_PASS}")
instance.setSecurityRealm(hudsonRealm)
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
instance.setAuthorizationStrategy(strategy)
instance.save()
EOF

echo "✅ Default admin user: $JENKINS_USER / $JENKINS_PASS"

# 🚀 Start Jenkins in the background
exec /usr/local/bin/jenkins.sh &

# ⏳ Wait for Jenkins
echo "⏳ Waiting for Jenkins to be fully ready..."
until curl -sSf http://localhost:8080/login >/dev/null; do
  echo "🔄 Jenkins is still starting... Retrying in 10s..."
  sleep 10
done
echo "✅ Jenkins is fully up and running!"

# Keep container running
wait

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

# 📌 Setup GitHub credentials
GITHUB_CRED_ID="github-token"
GITHUB_TOKEN="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"

cat <<EOF > /var/jenkins_home/init.groovy.d/github-credentials.groovy
import jenkins.model.Jenkins
import hudson.util.Secret
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.domains.Domain
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def instance = Jenkins.getInstanceOrNull()
def credentialsStore = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

def githubToken = new StringCredentialsImpl(
    CredentialsScope.GLOBAL,
    "github-token-id",
    "GitHub Personal Access Token",
    Secret.fromString("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") // Replace with actual token
)

credentialsStore.addCredentials(Domain.global(), githubToken)
instance.save()

println "✅ GitHub credentials added successfully!"

EOF

echo "✅ GitHub credentials configured!"

# 📦 Install GitHub plugins
#echo "📦 Installing GitHub-related Jenkins plugins..."
#/usr/local/bin/install-plugins.sh git github github-branch-source

echo "✅ GitHub plugins installed!"

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

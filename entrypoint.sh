#!/bin/bash
set -e  # Exit script on error

# Start Jenkins in the background
echo "🚀 Starting Jenkins..."
exec /usr/local/bin/jenkins.sh &

# Wait for Jenkins setup to complete
echo "⏳ Waiting for Jenkins to complete setup..."
MAX_RETRIES=50
SLEEP_INTERVAL=5
JENKINS_URL="http://localhost:8080"

for ((i=1; i<=MAX_RETRIES; i++)); do
    if curl -sSf "${JENKINS_URL}/login" > /dev/null 2>&1; then
        echo "✅ Jenkins is fully up and running!"
        break
    fi
    echo "🔄 Jenkins is still starting... Attempt $i of $MAX_RETRIES. Retrying in ${SLEEP_INTERVAL}s..."
    sleep $SLEEP_INTERVAL
done

# If Jenkins didn't start, exit with error
if ! curl -sSf "${JENKINS_URL}/login" > /dev/null 2>&1; then
    echo "❌ Jenkins did not start within expected time. Exiting..."
    exit 1
fi

echo "🚀 Jenkins is up and running!"

# Disable Setup Wizard - Prevents initial admin password prompt
echo "🛠 Disabling Jenkins Setup Wizard..."
mkdir -p /var/jenkins_home/init.groovy.d
cat <<EOF > /var/jenkins_home/init.groovy.d/basic-security.groovy
import jenkins.model.*
import hudson.security.*
import hudson.security.csrf.DefaultCrumbIssuer

def instance = Jenkins.getInstance()

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin', 'admin') // Username: admin, Password: admin
instance.setSecurityRealm(hudsonRealm)

// Set Authorization
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Enable CSRF Protection
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))

instance.save()
println "✅ Default admin user created! Login with admin:admin"
EOF

# Restart Jenkins to apply security settings
echo "🔄 Restarting Jenkins to apply security settings..."
kill $(pgrep -f "jenkins.war")
exec /usr/local/bin/jenkins.sh &

# Wait for Jenkins to restart
echo "⏳ Waiting for Jenkins restart..."
sleep 30

# Ensure Jenkins CLI is available before running CLI commands
JENKINS_CLI="/var/jenkins_home/jenkins-cli.jar"

echo "📥 Downloading jenkins-cli.jar..."
while ! wget -q --spider "${JENKINS_URL}/jnlpJars/jenkins-cli.jar"; do
    echo "🔄 Jenkins CLI not available yet. Retrying in 10s..."
    sleep 10
done
wget "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -O "$JENKINS_CLI"
echo "✅ jenkins-cli.jar downloaded successfully!"

# Add GitHub Token as Credential in Jenkins
GITHUB_TOKEN=${GITHUB_TOKEN:-"YOUR_GITHUB_PAT_HERE"}

cat <<EOF > /var/jenkins_home/github-credentials.xml
<com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>github-pat</id>
  <description>GitHub Personal Access Token</description>
  <secret>$GITHUB_TOKEN</secret>
</com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
EOF

# Add GitHub token to Jenkins using CLI
echo "🔑 Adding GitHub credentials to Jenkins..."
java -jar "$JENKINS_CLI" -s "${JENKINS_URL}" create-credentials-by-xml system::system::jenkins _ < /var/jenkins_home/github-credentials.xml
echo "✅ GitHub credentials added successfully!"

# Keep container running
wait

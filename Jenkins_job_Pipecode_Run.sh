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
# 🚀 Start Jenkins in the background
exec /usr/local/bin/jenkins.sh &

# ⏳ Wait for Jenkins
echo "⏳ Waiting for Jenkins to be fully ready..."
until curl -sSf http://localhost:8080/login >/dev/null; do
  echo "🔄 Jenkins is still starting... Retrying in 10s..."
  sleep 10
done
echo "✅ Jenkins is fully up and running!"

# 📥 Ensure Jenkins CLI is available
if [ ! -f /var/jenkins_home/jenkins-cli.jar ]; then
  echo "📥 Downloading Jenkins CLI..."
  curl -sSf http://localhost:8080/jnlpJars/jenkins-cli.jar -o /var/jenkins_home/jenkins-cli.jar
fi

if [ ! -f /var/jenkins_home/jenkins-cli.jar ]; then
  echo "❌ Failed to download jenkins-cli.jar. Exiting..."
  exit 1
fi
echo "✅ Jenkins CLI ready!"


# 📌 Creating Jenkinsfile
JENKINSFILE_PATH="/var/jenkins_home/Jenkinsfile"

if [ ! -f "$JENKINSFILE_PATH" ]; then
  echo "❌ Jenkinsfile not found at $JENKINSFILE_PATH! Exiting..."
  exit 1
fi

echo "📌 Creating Jenkinsfile..."
cat <<EOF > $JENKINSFILE_PATH
pipeline {
    agent any

    environment {
        GIT_REPO = 'https://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@github.com/ragothamang/sel-in-jenkins-docker-container-2025.git'
        WORK_DIR = '/var/jenkins_home/workspace/automation-suite'
        REPORT_PATH = "${WORK_DIR}/target/surefire-reports"
        RECIPIENTS = 'ragothamanu@gmail.com'
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    echo "🔄 Cloning GitHub repository..."
                    sh "rm -rf ${WORK_DIR} && git clone ${GIT_REPO} ${WORK_DIR}"
                    echo "✅ Repository cloned successfully!"
                }
            }
        }

        stage('Build & Test') {
            steps {
                dir(WORK_DIR) {
                    sh 'mvn clean test'
                }
            }
        }

        stage('Archive Test Reports') {
            steps {
                archiveArtifacts artifacts: '**/surefire-reports/*.xml', fingerprint: true
            }
        }

        stage('Send Email Notification') {
            steps {
                script {
                    emailext(
                        subject: "🔍 Selenium Test Report",
                        body: "✅ Automation test execution completed. Please find the attached report.",
                        recipientProviders: [[$class: 'DevelopersRecipientProvider']],
                        to: RECIPIENTS,
                        attachmentsPattern: "**/surefire-reports/*.xml",
                        mimeType: 'text/html'
                    )
                    echo "📧 Test report emailed successfully!"
                }
            }
        }
    }

    post {
        always {
            echo "📌 Pipeline execution completed!"
        }
    }
}

EOF
echo "✅ Jenkinsfile created successfully!"



# 📌 Create and trigger Pipeline Job
echo "📌 Creating Pipeline Job..."

JENKINS_JOB_NAME="MyPipeline"
JENKINS_SCRIPT=$(cat $JENKINSFILE_PATH)


cat <<EOF | java -jar /var/jenkins_home/jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin create-job $JENKINS_JOB_NAME
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Automated Pipeline Job</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps">
    <script><![CDATA[$JENKINS_SCRIPT]]></script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

echo "✅ Pipeline Job '$JENKINS_JOB_NAME' Created Successfully!"

# 🚀 Trigger First Build
java -jar /var/jenkins_home/jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin build $JENKINS_JOB_NAME
echo "🚀 Pipeline Job '$JENKINS_JOB_NAME' Triggered Successfully!"

#tail -f /dev/null
# Keep container running
#wait
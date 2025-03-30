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

# 📌 Configure Email Notification in Jenkins
cat <<EOF > /var/jenkins_home/init.groovy.d/jenkins-email.groovy
import jenkins.model.*
import hudson.tasks.Mailer

def jenkins = Jenkins.instance
def mailer = jenkins.getExtensionList(Mailer.DescriptorImpl.class)[0]

// ✅ Set SMTP Server Details
mailer.setSmtpHost("smtp.gmail.com")
mailer.setSmtpPort("465")
mailer.setAuthentication("ragothamanu@gmail.com", "cfodkoxxngmurypv")
mailer.setUseSsl(false)
mailer.setUseTls(true)
mailer.setReplyToAddress("ragothamanu@gmail.com")
mailer.setCharset("UTF-8")
mailer.save()

println "✅ Email Notification Configured Successfully!"
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
cat <<'EOF' > $JENKINSFILE_PATH
pipeline {
    agent any

    environment {
        WORK_DIR = '/var/jenkins_home/workspace/automation-suite'
        REPORT_PATH = "${WORK_DIR}/extent-reports"
        TEST_REPORTS = "${WORK_DIR}/target/surefire-reports"
        RECIPIENTS = 'ragothamanu@gmail.com'
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    echo "🔄 Cloning GitHub repository..."
                    sh """
                    rm -rf $WORK_DIR
                    git clone https://github.com/ragothamang/sel-in-jenkins-docker-container-2025.git $WORK_DIR
                    """
                    echo "✅ Repository cloned successfully!"
                }
            }
        }

        stage('Build & Test') {
            steps {
                dir(WORK_DIR) {
                    script {
                        def result = sh(script: 'mvn clean test', returnStatus: true)
                        if (result != 0) {
                            error("❌ Maven tests failed. Stopping pipeline execution.")
                        }
                        echo "✅ Maven tests completed successfully!"
                    }
                }
            }
        }

        stage('Ensure Reports Exist') {
            steps {
                script {
                    if (!fileExists("${REPORT_PATH}")) {
                        echo "⚠️ Report path missing. Copying from test reports..."
                        sh "mkdir -p ${REPORT_PATH} && cp -r ${TEST_REPORTS}/* ${REPORT_PATH}/ || echo '⚠️ No reports found to copy!'"
                    }
                }
            }
        }

        stage('Archive Test Reports') {
            steps {
                script {
                    def reportExists = sh(script: "ls ${REPORT_PATH}/*.html 2>/dev/null | wc -l", returnStdout: true).trim()
                    if (reportExists == '0') {
                        echo "⚠️ No reports found! Skipping archiving."
                    } else {
                        echo "✅ Archiving test reports..."
                        archiveArtifacts artifacts: "${REPORT_PATH}/extent-report.html", allowEmptyArchive: false
                    }
                }
            }
        }

        stage('Send Email Notification') {
            steps {
                script {
                    def reportExists = sh(script: "ls ${REPORT_PATH}/*.html 2>/dev/null | wc -l", returnStdout: true).trim()
                    if (reportExists == '0') {
                        echo "⚠️ No reports found! Skipping email notification."
                    } else {
                        emailext(
                            subject: "🔍 Selenium Test Report - ${currentBuild.fullDisplayName}",
                            body: """
                                <p>✅ Automation test execution completed.</p>
                                <p>Build Status: <b>${currentBuild.currentResult}</b></p>
                                <p>Click <a href="${env.BUILD_URL}">here</a> to view the full report.</p>
                            """,
                            to: RECIPIENTS,
                            attachmentsPattern: "**/extent-reports/*.html",
                            mimeType: 'text/html'
                        )
                        echo "📧 Test report emailed successfully!"
                    }
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

tail -f /dev/null
# Keep container running
#wait
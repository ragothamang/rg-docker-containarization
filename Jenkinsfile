pipeline {
    agent {
        docker {
            image 'rg-img-sel-java-2025'
            args '--user root'
        }
    }

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
                    sh '''
						"rm -rf /var/jenkins_home/workspace/automation-suite && 
						git clone https://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@github.com/ragothamang/sel-in-jenkins-docker-container-2025.git /var/jenkins_home/workspace/automation-suite"						
					'''
                    echo "✅ Repository cloned successfully!"
                }
            }
        }

        stage('Build & Test') {
            steps {
                dir(WORK_DIR) {
                    sh '''
						'mvn clean test'
					'''
                }
            }
        }

        stage('Archive Test Reports') {
            steps {
                archiveArtifacts artifacts: '**/extent-reports/*.html', fingerprint: true
            }
        }

        stage('Send Email Notification') {
            steps {
                script {
                    emailext(
                        subject: "🔍 Selenium Test Report",
						body: "✅ Automation test execution completed. Please find the attached report.",
						recipientProviders: [developers(), requestor()],
						to: RECIPIENTS,
						attachmentsPattern: "**/extent-reports/*.html",
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

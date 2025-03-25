pipeline {
    agent any

    environment {
        GITHUB_CREDENTIALS = credentials('github-pat') // Jenkins Credential Store ID
        GIT_REPO = 'https://github.com/ragothamang/sel-in-jenkins-docker-container-2025.git'
        WORK_DIR = '/var/jenkins_home/workspace/automation-suite'
        REPORT_PATH = '/var/jenkins_home/workspace/automation-suite/extent-reports/extent-report.html'
        RECIPIENTS = 'ragothamanu@gmail.com'
    }

    stages {
        stage('Start Jenkins in Docker') {
            steps {
                sh 'docker-compose up -d --build'
            }
        }

stage('Wait for Jenkins to be Ready') {
    steps {
        sh '''
        echo "⏳ Waiting for Jenkins to be fully ready..."

        MAX_RETRIES=30
        SLEEP_INTERVAL=10
        CONTAINER_NAME="rg-cntr-sel-java-2025"

        for ((i=1; i<=MAX_RETRIES; i++)); do
            # Check if Jenkins API is accessible
            if curl -sSf "http://localhost:8080/api/json" --connect-timeout 5 > /dev/null 2>&1; then
                echo "✅ Jenkins is fully up and running!"
                exit 0
            fi

            echo "🔄 Jenkins is still starting... Attempt $i of $MAX_RETRIES. Retrying in ${SLEEP_INTERVAL}s..."
            sleep $SLEEP_INTERVAL
        done

        echo "❌ Jenkins did not start within expected time. Exiting..."
        exit 1
        '''
    }
}






        stage('Clone Repository Inside Jenkins Container') {
            steps {
                sh '''
                docker exec rg-cntr-sel-java-2025 bash -c "
                git config --global credential.helper cache
                git config --global user.email 'jenkins@example.com'
                git config --global user.name 'Jenkins'

                if [ ! -d '$WORK_DIR/.git' ]; then
                    git clone https://$GITHUB_CREDENTIALS@github.com/ragothamang/sel-in-jenkins-docker-container-2025.git $WORK_DIR
                else
                    cd $WORK_DIR && git pull
                fi"
                '''
            }
        }

        stage('Run Automation Tests Inside Jenkins Container') {
            steps {
                sh '''
                echo "Running tests inside Jenkins container..."
                docker exec rg-cntr-sel-java-2025 bash -c "cd $WORK_DIR && mvn clean test"
                '''
            }
        }

        stage('Send Email with Extent Report') {
            steps {
                script {
                    sh '''
                    docker cp rg-cntr-sel-java-2025:${REPORT_PATH} .
                    '''
                    emailext(
                        subject: "Selenium Test Report",
                        body: "Please find the attached Extent report.",
                        recipientProviders: [[$class: 'DevelopersRecipientProvider']],
                        to: RECIPIENTS,
                        attachmentsPattern: "extent-report.html",
                        mimeType: 'text/html'
                    )
                }
            }
        }
    }

    post {
        always {
            sh 'docker-compose down'
        }
    }
}

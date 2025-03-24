pipeline {
    agent any

    environment {
        GITHUB_CREDENTIALS = credentials('github-pat')
        GIT_REPO = 'https://github.com/ragothamang/sel-in-jenkins-docker-container-2025.git'
        WORK_DIR = '/var/jenkins_home/workspace/automation-suite'
    }

    stages {
        stage('Clone Repository') {
            steps {
                sh '''
                git config --global credential.helper cache
                git config --global user.email "jenkins@example.com"
                git config --global user.name "Jenkins"

                if [ ! -d "$WORK_DIR/.git" ]; then
                    git clone https://$GITHUB_CREDENTIALS@github.com/ragothamang/sel-in-jenkins-docker-container-2025.git $WORK_DIR
                else
                    cd $WORK_DIR && git pull
                fi
                '''
            }
        }
    }
}

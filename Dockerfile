FROM jenkins/jenkins:lts

USER root

# Install required packages
RUN apt-get update && apt-get install -y \
    git \
    maven \
    curl \
    jq \
	wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Jenkins plugins
COPY jenkins-plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

COPY Jenkinsfile /var/jenkins_home/Jenkinsfile
RUN chmod +x /var/jenkins_home/Jenkinsfile

#COPY Jenkinsfile /var/jenkins_home/Jenkinsfile-Basic
#RUN chmod +x /var/jenkins_home/Jenkinsfile-Basic


# Set up entrypoint
COPY Jenkins_job_Pipecode_Run.sh /Jenkins_job_Pipecode_Run.sh
RUN chmod +x /Jenkins_job_Pipecode_Run.sh


ENTRYPOINT ["/Jenkins_job_Pipecode_Run.sh"]

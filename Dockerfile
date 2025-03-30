FROM jenkins/jenkins:lts

USER root

# Install required packages
RUN apt-get update && apt-get install -y \
    software-properties-common \
    git \
    maven \
    curl \
    jq \
    wget \
    unzip \
    gnupg \
    && apt-get install -y firefox-esr \
    && rm -rf /var/lib/apt/lists/*

# Install Java 17
RUN apt-get update && apt-get install -y openjdk-17-jdk

# Set JAVA_HOME to Java 17
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# Verify Java installation
RUN java -version
	
	
# Install Geckodriver
RUN wget https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz \
    && tar -xzf geckodriver-v0.33.0-linux64.tar.gz \
    && mv geckodriver /usr/local/bin/ \
    && chmod +x /usr/local/bin/geckodriver \
    && rm geckodriver-v0.33.0-linux64.tar.gz

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

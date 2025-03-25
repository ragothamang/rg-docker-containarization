# Base Image - Jenkins LTS
FROM jenkins/jenkins:lts

# Switch to root user for installation
USER root

# Install Java, Maven, Git, Curl, Wget, Unzip
RUN apt-get update && \
    apt-get install -y openjdk-17-jdk maven git curl wget unzip firefox-esr dos2unix && \
    rm -rf /var/lib/apt/lists/*

# Set Java and Maven environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# Install Chrome and Chromedriver for Selenium
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    dpkg -i google-chrome-stable_current_amd64.deb || apt-get -fy install && \
    rm google-chrome-stable_current_amd64.deb

RUN CHROME_DRIVER_VERSION=$(curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE) && \
    wget -N https://chromedriver.storage.googleapis.com/${CHROME_DRIVER_VERSION}/chromedriver_linux64.zip && \
    unzip chromedriver_linux64.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/chromedriver && \
    rm chromedriver_linux64.zip

# Install Jenkins plugins (Pipeline, Git, Email)
COPY jenkins-plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && dos2unix /entrypoint.sh

# Switch to Jenkins user
USER jenkins

# Entrypoint script to initialize Jenkins
ENTRYPOINT ["/entrypoint.sh"]

#!/bin/bash
set -e

# Start Jenkins in the background
exec /usr/local/bin/jenkins.sh &

# Wait for Jenkins to fully start
echo "Waiting for Jenkins to start..."
while ! curl -s http://localhost:8080/login > /dev/null; do
    sleep 5
done

echo "Jenkins is up and running!"

# Get GitHub token from environment variable
GITHUB_TOKEN="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"

# Create credentials XML file
cat <<EOF > /var/jenkins_home/github-credentials.xml
<com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>github-pat</id>
  <description>GitHub Personal Access Token</description>
  <secret>$GITHUB_TOKEN</secret>
</com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
EOF

# Add GitHub token to Jenkins
echo "Adding GitHub credentials..."
java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ create-credentials-by-xml system::system::jenkins _ < /var/jenkins_home/github-credentials.xml

echo "GitHub credentials added successfully!"

# Keep container running
wait

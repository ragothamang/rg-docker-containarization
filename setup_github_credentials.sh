#!/bin/bash

# 🚀 Step 1: Get GitHub Token (Replace with your secure method)
GITHUB_TOKEN="your_github_pat_here"  # Replace with a secure retrieval method
CREDENTIAL_ID="github-pat" # Jenkins Credential ID

# 🚀 Step 2: Create Credentials XML File
cat <<EOF > github-credentials.xml
<com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>$CREDENTIAL_ID</id>
  <description>GitHub Personal Access Token</description>
  <secret>$GITHUB_TOKEN</secret>
</com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
EOF

echo "✅ GitHub Credentials XML file created."

# 🚀 Step 3: Copy the Credentials File into the Jenkins Container
JENKINS_CONTAINER="jenkins-container"  # Replace with your Jenkins container name
docker cp github-credentials.xml $JENKINS_CONTAINER:/var/jenkins_home/github-credentials.xml

echo "✅ Credentials file copied into the Jenkins container."

# 🚀 Step 4: Add Credentials Using Jenkins CLI
docker exec -it $JENKINS_CONTAINER java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar \
    -s http://localhost:8080/ \
    create-credentials-by-xml system::system::jenkins _ < /var/jenkins_home/github-credentials.xml

echo "✅ GitHub PAT added to Jenkins Credentials Store."

# 🚀 Step 5: Verify Credentials
docker exec -it $JENKINS_CONTAINER java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar \
    -s http://localhost:8080/ \
    list-credentials system::system::jenkins _

echo "✅ Credentials verification complete."

# 🚀 Step 6: Restart Jenkins to Apply Changes
docker restart $JENKINS_CONTAINER
echo "✅ Jenkins restarted to apply changes."

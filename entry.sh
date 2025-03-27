#!/bin/bash
set -e

# Ensure Jenkins owns its home directory
chown -R jenkins:jenkins /var/jenkins_home
su - jenkins
# Start Jenkins as the Jenkins user
/usr/local/bin/jenkins.sh

FROM jenkins/jenkins:lts
RUN /usr/local/bin/install-plugins.sh git workflow-aggregator lockable-resources
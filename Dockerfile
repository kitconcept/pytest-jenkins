FROM jenkins/jenkins:lts

# install system packages
USER root
RUN apt-get update
RUN apt-get install -y python-pip
RUN apt-get install -y python-virtualenv

# install chrome
RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add
RUN echo "deb [arch=amd64]  http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
RUN apt-get -y update
RUN apt-get -y install google-chrome-stable

# install chromedriver
RUN wget "http://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip"
RUN unzip chromedriver_linux64.zip
RUN mv chromedriver /usr/local/bin

# install jenkins add-ons
USER jenkins
RUN /usr/local/bin/install-plugins.sh git workflow-aggregator lockable-resources docker-build-publish parameterized-scheduler robot

# copy files
COPY tests/robot-tests/test1.robot  /var/jenkins_home/jobs/robot-tests/test1.robot
COPY tests/robot-tests/test2.robot  /var/jenkins_home/jobs/robot-tests/test2.robot

USER root
RUN chown -R jenkins:jenkins  /var/jenkins_home/jobs/robot-tests

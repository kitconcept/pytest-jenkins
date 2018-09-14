FROM jenkins/jenkins:lts

# install system packages
USER root
RUN apt-get update
RUN apt-get install -y python-pip
RUN apt-get install -y python-virtualenv

# Create a default user
RUN useradd automation --shell /bin/bash --create-home

# install chrome
RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add
RUN echo "deb [arch=amd64]  http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
RUN apt-get -y update
RUN apt-get -y install google-chrome-stable

# install chromedriver
RUN wget "http://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip"
RUN unzip chromedriver_linux64.zip
RUN mv chromedriver /usr/local/bin

RUN apt-get -yqq update && \
  apt-get -yqq install curl unzip && \
  apt-get -yqq install xvfb tinywm && \
  apt-get -yqq install fonts-ipafont-gothic xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic && \
  apt-get -yqq install python && \
  rm -rf /var/lib/apt/lists/*

# Install Chrome WebDriver
# RUN CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
#   mkdir -p /opt/chromedriver-$CHROMEDRIVER_VERSION && \
#   curl -sS -o /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip && \
#   unzip -qq /tmp/chromedriver_linux64.zip -d /opt/chromedriver-$CHROMEDRIVER_VERSION && \
#   rm /tmp/chromedriver_linux64.zip && \
#   chmod +x /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver && \
#   ln -fs /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver /usr/local/bin/chromedriver

# Install Google Chrome
RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list && \
  apt-get -yqq update && \
  apt-get -yqq install google-chrome-stable && \
  rm -rf /var/lib/apt/lists/*

# install jenkins add-ons
USER jenkins
RUN /usr/local/bin/install-plugins.sh git workflow-aggregator lockable-resources docker-build-publish parameterized-scheduler robot

# copy files
COPY tests/robot-tests/test1.robot  /var/jenkins_home/jobs/robot-tests/test1.robot
COPY tests/robot-tests/test2.robot  /var/jenkins_home/jobs/robot-tests/test2.robot

USER root
RUN chown -R jenkins:jenkins  /var/jenkins_home/jobs/robot-tests

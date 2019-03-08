
FROM jenkins/jenkins:2.146

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Jenkins is fully configured, no configure wizard, please
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
RUN echo 2.146 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state
RUN echo 2.146 > /usr/share/jenkins/ref/jenkins.install.InstallUtil.lastExecVersion

COPY default-user.groovy /usr/share/jenkins/ref/init.groovy.d/
COPY config.groovy /usr/share/jenkins/ref/init.groovy.d/

USER root

RUN mkdir /cran

RUN apt-get update && apt-get install -y rsync

RUN apt-get install -y r-base-core

RUN echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' \
    >> ~/.Rprofile && \
    Rscript -e 'install.packages("desc")'

RUN apt-get install -y acmetool

RUN mkdir -p /var/nginx-data && \
    chown -R jenkins:jenkins /var/nginx-data

ENV ACME_STATE_DIR /var/nginx-data/acmetool

USER jenkins

COPY scripts /var/jenkins_home/scripts

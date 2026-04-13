FROM jenkins/jenkins:lts

USER root

# Install Docker CLI so Jenkins can build images
RUN apt-get update && apt-get install -y \
    docker.io \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -f docker && usermod -aG docker jenkins

# Install Jenkins plugins
RUN jenkins-plugin-cli --plugins \
    git \
    workflow-aggregator \
    docker-workflow \
    credentials-binding \
    blueocean

USER jenkins
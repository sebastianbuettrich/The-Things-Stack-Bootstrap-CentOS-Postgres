#!/usr/bin/env bash

set -e

# Install Docker:

sudo yum update -y

sudo yum install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

sudo yum install -y yum-utils
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install -y docker-ce docker-ce-cli containerd.io

sudo usermod -aG docker $USER

sudo systemctl start docker

# Install Docker Compose:

sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Prepare The Things Stack folder:

if [[ ! -d /app/the-things-stack ]];
then
  sudo mkdir -p /app/the-things-stack
  sudo chown $USER:$USER /app/the-things-stack
fi

cd /app/the-things-stack

if [[ ! -d ./acme ]];
then
  sudo mkdir ./acme
  sudo chown 886:886 ./acme
fi

# Prepare postgres folder

sudo mkdir /var/lib/postgresql
sudo mkdir /var/lib/postgresql/data

FROM ubuntu:22.04 as docker-compose-downloader
ARG TARGETARCH

FROM ubuntu:22.04
LABEL maintainer="Bitbucket Pipelines <pipelines-feedback@atlassian.com>"

ARG DEBIAN_FRONTEND=noninteractive


# Install base dependencies
RUN apt-get update \
    && apt-get install -y \
        software-properties-common \
    && add-apt-repository ppa:git-core/ppa -y \
    && apt-get install -y \
        autoconf \
        build-essential \
        ca-certificates \
        pkg-config \
        wget \
        xvfb \
        curl \
        git \
        ant \
        ssh-client \
        unzip \
        iputils-ping \
        zip \
        jq \
        gettext-base \
        tar \
        parallel \
    && rm -rf /var/lib/apt/lists/*
    
# Composer
FROM composer:2.5.4 AS php-composer
RUN /usr/bin/composer -v

# PHP
FROM php:8.1.27-cli AS php

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# install docker-compose

# Install nvm with node and npm
ENV NODE_VERSION=18.16.1 \
    NVM_DIR=/root/.nvm \
    NVM_VERSION=0.39.2 \
    NVM_SHA256=c1e672cd63737cd3e166ad43dffcb630a3bea07484705eae303c4b6c3e42252a

RUN curl https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh -o install_nvm.sh \
    && echo "${NVM_SHA256} install_nvm.sh" | sha256sum -c - \
    && bash install_nvm.sh \
    && rm -rf install_nvm.sh \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# Set node path
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules

# Default to UTF-8 file.encoding
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LANGUAGE=C.UTF-8

# Xvfb provide an in-memory X-session for tests that require a GUI
ENV DISPLAY=:99

# Set the path.
ENV PATH=$NVM_DIR:$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Create dirs and users
RUN mkdir -p /opt/atlassian/bitbucketci/agent/build \
    && sed -i '/[ -z \"PS1\" ] && return/a\\ncase $- in\n*i*) ;;\n*) return;;\nesac' /root/.bashrc \
    && useradd --create-home --shell /bin/bash --uid 1000 pipelines

WORKDIR /opt/atlassian/bitbucketci/agent/build
ENTRYPOINT ["/bin/bash"]

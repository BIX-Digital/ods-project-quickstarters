FROM centos:7

MAINTAINER "Andreas Bellmann" <andreas.bellmann@opitz-consulting.com>

ENV OS_CLI_VERSION_MAJOR 3.4
ENV OS_CLI_VERSION_MINOR 1.2-1

RUN yum -y install curl ca-certificates bash-completion vim git && \
    curl -s -L https://mirror.openshift.com/pub/openshift-v3/clients/3.7.0-0.198.0/linux/oc.tar.gz -o /tmp/oc.tar.gz && \
    tar zxvf /tmp/oc.tar.gz -C /tmp/ && \ 
    mv /tmp/oc /usr/bin/ && \
    rm -rf /tmp/oc.tar.gz  && \
    oc completion bash > ~/oc-bash-completion.sh && \
    echo source ~/oc-bash-completion.sh >> ~/.bashrc && \
    oc version

WORKDIR /data
COPY scripts /data


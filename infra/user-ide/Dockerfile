FROM codercom/code-server:3.4.1

ARG OPENSHIFT_CLIENT_TOOL=https://downloads-openshift-console.ocp.aws.puzzle.ch/amd64/linux/oc.tar
ARG KUBECTL=https://storage.googleapis.com/kubernetes-release/release/
ARG KUBECTL_STABLE=https://storage.googleapis.com/kubernetes-release/release/stable.txt
ARG KUBECTX=https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx
ARG KUBENS=https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens
ARG HELM_CLI=https://mirror.openshift.com/pub/openshift-v4/clients/helm/latest/helm-linux-amd64
ARG ODO=https://mirror.openshift.com/pub/openshift-v4/clients/odo/latest/odo-linux-amd64
ARG KUSTOMIZE_CLI=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.8.0/kustomize_v3.8.0_linux_amd64.tar.gz

USER root

RUN apt-get update && apt-get install bash-completion

USER coder

RUN mkdir -p ~/.local/bin \
    && curl ${HELM_CLI} -o ~/.local/bin/helm \
    && curl ${OPENSHIFT_CLIENT_TOOL} -o ~/.local/bin/oc.tar &&  tar -xvf ~/.local/bin/oc.tar -C ~/.local/bin/ && rm -rf ~/.local/bin/oc.tar \
    && curl -L ${KUBECTL}`curl -s ${KUBECTL_STABLE}`/bin/linux/amd64/kubectl -o ~/.local/bin/kubectl \
    && curl ${KUBECTX} -o ~/.local/bin/kubectx \
    && curl ${KUBENS} -o ~/.local/bin/kubens \
    && curl ${ODO} -o ~/.local/bin/odo \
    && curl -L ${KUSTOMIZE_CLI} -o ~/.local/bin/kustomize.tar.gz && tar xvfz ~/.local/bin/kustomize.tar.gz -C ~/.local/bin/ && rm -rf ~/.local/bin/kustomize.tar.gz \
    && chmod +x ~/.local/bin/*

RUN echo "PATH=$PATH:~/.local/bin/" >> .bashrc \
    && echo "source <(kubectl completion bash)" >> .bashrc \
    && echo "source <(oc completion bash)" >> .bashrc \
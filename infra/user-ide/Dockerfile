FROM codercom/code-server:4.17.1

ARG ARGOCD_CLI=https://github.com/argoproj/argo-cd/releases/download/v2.3.9/argocd-linux-amd64
ARG HELM_CLI=https://get.helm.sh/helm-v3.10.2-linux-amd64.tar.gz
ARG K8S_DEBUGBOX=https://github.com/puzzle/k8s-debugbox/releases/download/v1.0.5/k8s-debugbox-v1.0.5.tar.gz
ARG KUBECTL=https://storage.googleapis.com/kubernetes-release/release/
ARG KUBECTL_STABLE=https://storage.googleapis.com/kubernetes-release/release/stable.txt
ARG KUBECTX=https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx
ARG KUBENS=https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens
ARG KUSTOMIZE_CLI=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.8.0/kustomize_v3.8.0_linux_amd64.tar.gz
ARG TEKTON_CLI=https://github.com/tektoncd/cli/releases/download/v0.10.0/tkn_0.10.0_Linux_x86_64.tar.gz
ARG ODO=https://mirror.openshift.com/pub/openshift-v4/clients/odo/latest/odo-linux-amd64
ARG OPENSHIFT_CLIENT_TOOL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz

USER root

RUN apt-get update && apt-get install bash-completion wget

RUN mkdir -p ~/.local/bin \
    && curl -L ${ARGOCD_CLI} -o /usr/local/bin/argocd \
    && curl ${HELM_CLI} -o /tmp/helm.tar.gz && tar xvfz /tmp/helm.tar.gz -C /tmp && cp -a /tmp/linux-amd64/helm  /usr/local/bin/helm  && rm -rf /tmp/helm.tar.gz && rm -rf /tmp/linux-amd64 \
    && curl -L ${K8S_DEBUGBOX} -o /tmp/k8s-debugbox.tar.gz && tar xvfz /tmp/k8s-debugbox.tar.gz -C /tmp && cd /tmp/k8s-debugbox-v1.0.5/ && ./install.sh && cd - && rm -rf /tmp/k8s-debugbox* \
    && curl -L ${KUBECTL}`curl -s ${KUBECTL_STABLE}`/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
    && curl ${KUBECTX} -o /usr/local/bin/kubectx \
    && curl ${KUBENS} -o /usr/local/bin/kubens \
    && curl -L ${KUSTOMIZE_CLI} -o ~/.local/bin/kustomize.tar.gz && tar xvfz ~/.local/bin/kustomize.tar.gz -C /usr/local/bin/ && rm -rf ~/.local/bin/kustomize.tar.gz \
    && curl -L ${TEKTON_CLI} -o ~/.local/bin/tkn.tar.gz && tar xvfz ~/.local/bin/tkn.tar.gz -C /usr/local/bin/ && rm -rf ~/.local/bin/tkn.tar.gz \
    && curl ${ODO} -o /usr/local/bin/odo \
    && curl ${OPENSHIFT_CLIENT_TOOL} -o ~/.local/bin/oc.tar &&  tar -xvf ~/.local/bin/oc.tar -C /usr/local/bin/ && rm -rf ~/.local/bin/oc.tar \
    && chmod +x /usr/local/bin/*

USER coder

RUN oc completion bash | sudo tee /etc/bash_completion.d/oc_bash_completion \
    && kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl_bash_completion

# files copied back in entrypoint
RUN mkdir -p /tmp/coder \
    && cp -a ~/.bashrc /tmp/coder/ \
    && cp -a ~/.bash_logout /tmp/coder/ \
    && cp -a ~/.profile /tmp/coder/

COPY settings.json /tmp/coder/
COPY container-entrypoint.sh /

ENTRYPOINT ["/container-entrypoint.sh"]
CMD ["--host", "0.0.0.0", "."]

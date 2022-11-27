FROM python:3.9.10 as base
ENV SOPS_VERSION=3.7.3
ENV GITLEAKS_VERSION=8.11.2
ENV HADOLINT_VERSION=2.10.0
WORKDIR /tmp
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  sshpass ansible curl ca-certificates direnv && \
  curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends kubectl && \
  rm -rf /var/cache/apt/archives
COPY ansible/dev-requirements.txt .
RUN pip install -r dev-requirements.txt && rm -f dev-requirements.txt

FROM base as builder
WORKDIR /tmp/builder

RUN dpkg --print-architecture > arch
RUN curl -LO https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.`cat arch` && \
  chmod +x sops-v${SOPS_VERSION}.linux.`cat arch` && \
  mv sops-v${SOPS_VERSION}.linux.`cat arch` /usr/local/bin/sops && \
  curl -sLS https://get.k3sup.dev | sh

RUN if [ `cat arch` == "amd64" ]; then echo x64 > arch; fi
RUN curl -LO https://github.com/zricethezav/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_`cat arch`.tar.gz && \
  tar zxvf gitleaks_${GITLEAKS_VERSION}_linux_`cat arch`.tar.gz && \
  mv gitleaks /usr/local/bin
RUN dpkg --print-architecture > arch
RUN if [ `cat arch` == "amd64" ]; then echo x86_64 > arch; fi
RUN curl -LO https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-`cat arch` && \
  chmod +x hadolint-Linux-`cat arch` && \
  mv hadolint-Linux-`cat arch` /usr/local/bin/hadolint

FROM base as staging
COPY --from=builder /usr/local/bin/sops /usr/local/bin/sops
COPY --from=builder /usr/local/bin/gitleaks /usr/local/bin/gitleaks
COPY --from=builder /usr/local/bin/hadolint /usr/local/bin/hadolint

FROM staging as development
WORKDIR /workspaces/infrastructure
ENV ANSIBLE_CONFIG=/workspaces/infrastructure/ansible/ansible.cfg
COPY ansible/galaxy-requirements.yml ansible/galaxy-requirements.yml
RUN ansible-galaxy install -r ansible/galaxy-requirements.yml
RUN echo "alias ap='cd /workspaces/infrastructure/ansible/playbooks && ansible-playbook'" >> /root/.bashrc \
  && echo "alias k='kubectl --kubeconfig /workspaces/infrastructure/kubeconfig'" >> /root/.bashrc \
  && echo 'eval "$(direnv hook bash)"' >> /root/.bashrc

FROM development
# ENV ANSIBLE_CONFIG=/infrastructure/ansible/ansible.cfg
# WORKDIR /infrastructure
# COPY ansible/ ansible/.
# COPY .sops.yaml .
# COPY ansible.cfg .
# RUN ansible-galaxy install -r ansible/galaxy-requirements.yml

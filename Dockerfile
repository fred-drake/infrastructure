FROM python:3.10 as base
ENV SOPS_VERSION=3.7.3
ENV GITLEAKS_VERSION=8.11.2
ENV HADOLINT_VERSION=2.10.0
ENV SEALED_SECRETS_VERSION=0.19.2
ENV YQ_VERSION=4.30.5
ENV BWS_VERSION=0.4.0
WORKDIR /tmp
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  sshpass ansible curl ca-certificates direnv apt-transport-https lsb-release \
  g++-arm-linux-gnueabihf libc6-dev-armhf-cross docker.io gcc-arm-linux-gnueabihf && \
  curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
  mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends kubectl && \
  curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
  apt-get update && apt-get install -y --no-install-recommends helm && \
  wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg && \
  echo "deb [arch=all,$(dpkg --print-architecture) signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | tee /etc/apt/sources.list.d/prebuilt-mpr.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends just && \
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
RUN curl -LO https://github.com/bitnami-labs/sealed-secrets/releases/download/v${SEALED_SECRETS_VERSION}/kubeseal-${SEALED_SECRETS_VERSION}-linux-`cat arch`.tar.gz && \
  tar zxvf kubeseal-${SEALED_SECRETS_VERSION}-linux-`cat arch`.tar.gz && \
  chmod +x kubeseal && \
  mv kubeseal /usr/local/bin
RUN if [ `cat arch` == "amd64" ]; then echo x64 > arch; fi
RUN curl -LO https://github.com/zricethezav/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_`cat arch`.tar.gz && \
  tar zxvf gitleaks_${GITLEAKS_VERSION}_linux_`cat arch`.tar.gz && \
  mv gitleaks /usr/local/bin
RUN dpkg --print-architecture > arch
RUN if [ `cat arch` == "amd64" ]; then echo x86_64 > arch; fi
RUN curl -LO https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-`cat arch` && \
  chmod +x hadolint-Linux-`cat arch` && \
  mv hadolint-Linux-`cat arch` /usr/local/bin/hadolint
RUN curl -LO https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_`cat arch` && \
  chmod +x yq_linux_`cat arch` && \
  mv yq_linux_`cat arch` /usr/local/bin/yq
RUN dpkg --print-architecture > arch
RUN if [ `cat arch` == "amd64" ]; then echo x86_64 > arch; fi
RUN if [ `cat arch` == "arm64" ]; then echo aarch64 > arch; fi
RUN curl -LO https://github.com/bitwarden/sdk/releases/download/bws-v${BWS_VERSION}/bws-`cat arch`-unknown-linux-gnu-${BWS_VERSION}.zip && \
  unzip bws-`cat arch`-unknown-linux-gnu-${BWS_VERSION}.zip && \
  chmod +x bws && \
  mv bws /usr/local/bin/bws


FROM base as staging
COPY --from=builder /usr/local/bin/sops /usr/local/bin/sops
COPY --from=builder /usr/local/bin/gitleaks /usr/local/bin/gitleaks
COPY --from=builder /usr/local/bin/hadolint /usr/local/bin/hadolint
COPY --from=builder /usr/local/bin/k3sup /usr/local/bin/k3sup
COPY --from=builder /usr/local/bin/kubeseal /usr/local/bin/kubeseal
COPY --from=builder /usr/local/bin/yq /usr/local/bin/yq
COPY --from=builder /usr/local/bin/bws /usr/local/bin/bws

FROM staging as development
WORKDIR /workspaces/infrastructure
ENV SOPS_AGE_KEY_FILE=/root/.age/ansible-key.txt
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

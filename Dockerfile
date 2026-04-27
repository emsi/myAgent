# syntax=docker/dockerfile:1.7
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG DEBIAN_FRONTEND=noninteractive

# Optional agent CLIs
ARG INSTALL_CODEX_CLI=1
ARG INSTALL_CLAUDE_CODE=1
ARG INSTALL_GEMINI_CLI=0
ARG INSTALL_OPENCODE=0

ENV AGENT_ENGINE=codex

SHELL ["/bin/bash", "-lc"]

# Install locations for global CLI binaries (system-wide, not /root)
ENV NPM_CONFIG_PREFIX=/usr/local
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=${CARGO_HOME}/bin:${PATH}

# Full-fat dev/workstation tools + Byobu (tmux backend; DO NOT install screen)
RUN apt-get update && apt-get install -y \
    byobu tmux \
    git git-lfs \
    ripgrep fd-find \
    curl wget \
    jq yq \
    fzf \
    bat \
    tree htop \
    zip unzip p7zip-full \
    rsync \
    openssh-client \
    lsof strace gdb \
    iproute2 iputils-ping dnsutils net-tools socat \
    ca-certificates \
    locales \
    man-db manpages manpages-dev \
    bash-completion \
    shellcheck \
    build-essential pkg-config cmake make gcc g++ \
    clang clang-format clang-tidy \
    ninja-build meson \
    autoconf automake libtool \
    nodejs npm \
    python3 python3-dev python3-pip python3-venv python-is-python3 \
    rustc cargo \
    vim \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 \
 && mkdir -p "${CARGO_HOME}/bin" \
 && rm -rf /var/lib/apt/lists/*

# Install gcloud CLI
RUN <<'EOF'
set -eux
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg
install -d -m 0755 /usr/share/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  > /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update
apt-get install -y --no-install-recommends google-cloud-cli
rm -rf /var/lib/apt/lists/*
EOF

# Install optional agent CLIs
RUN npm config set fund false \
 && npm config set audit false \
 && npm config set update-notifier false \
 && npm config set prefix "${NPM_CONFIG_PREFIX}" \
 && if [[ "${INSTALL_CODEX_CLI}" == "1" ]]; then npm install -g @openai/codex; fi \
 && if [[ "${INSTALL_CLAUDE_CODE}" == "1" ]]; then npm install -g @anthropic-ai/claude-code; fi \
 && if [[ "${INSTALL_GEMINI_CLI}" == "1" ]]; then npm install -g @google/gemini-cli; fi \
 && if [[ "${INSTALL_OPENCODE}" == "1" ]]; then npm install -g opencode-ai; fi

# Install gh CLI
RUN (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y \
	&& rm -rf /var/lib/apt/lists/*

RUN rm -rf /tmp/* /tmp/.[a-zA-Z0-9]*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV EDITOR=vi
ENV TERM=xterm-256color
ENV HOME=/agent
ENV AGENT_HOME=/agent

WORKDIR /workspace
VOLUME ["/agent"]

COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []

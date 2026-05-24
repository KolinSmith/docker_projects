FROM cgr.dev/chainguard/wolfi-base:latest

# Base packages + tools available in wolfi apk
RUN apk add --no-cache \
    git \
    nodejs \
    yamllint \
    python-3 \
    py3-pip \
    gitleaks \
    wget \
    docker-cli \
    docker-buildx

# Pip packages
# --root-user-action=ignore required; manylinux wheels don't work on musl
RUN pip install --quiet --root-user-action=ignore \
    checkov \
    "ansible-lint[community]"

# ruff — pip manylinux wheel fails on wolfi (musl libc); use musl binary
RUN wget -qO /tmp/ruff.tar.gz \
      https://github.com/astral-sh/ruff/releases/download/0.15.13/ruff-aarch64-unknown-linux-musl.tar.gz \
    && tar -xzf /tmp/ruff.tar.gz -C /tmp \
    && find /tmp -name ruff -type f -exec install -m 755 {} /usr/bin/ruff \; \
    && rm -rf /tmp/ruff*

# shellcheck — not in wolfi aarch64 apk; use binary
# wolfi has no /usr/local/bin — install to /usr/bin/
RUN wget -qO /tmp/shellcheck.tar.xz \
      https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.linux.aarch64.tar.xz \
    && tar -xJf /tmp/shellcheck.tar.xz -C /tmp \
    && find /tmp -name shellcheck -type f -exec install -m 755 {} /usr/bin/shellcheck \; \
    && rm -rf /tmp/shellcheck*

# scc
RUN wget -qO /tmp/scc.tar.gz \
      https://github.com/boyter/scc/releases/download/v3.3.4/scc_Linux_arm64.tar.gz \
    && tar -xzf /tmp/scc.tar.gz -C /tmp scc \
    && install -m 755 /tmp/scc /usr/bin/scc \
    && rm /tmp/scc.tar.gz /tmp/scc

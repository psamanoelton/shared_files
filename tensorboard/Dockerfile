FROM us-docker.pkg.dev/ml-oss-artifacts-published/ml-public-container/ml-build:latest

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

# Base system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  openjdk-11-jdk-headless \
  libxrandr2 \
  libatk1.0-0 \
  libatk-bridge2.0-0 \
  libcups2 \
  libdrm2 \
  libgtk-3-0 \
  libnspr4 \
  libnss3 \
  libxcomposite1 \
  libxdamage1 \
  libxfixes3 \
  libxss1 \
  libxkbcommon0 \
  libxshmfence1 \
  libgbm1 \
  libglib2.0-0 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  fonts-liberation \
  dos2unix \
  && rm -rf /var/lib/apt/lists/*

# Keep a real local JDK available for Bazel repository loading. The CI base
# image has Java installed, but Bazel 7.7.0's local_jdk autoconfiguration is
# not stable enough here after `bazel clean --expunge`.
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Python 3.12
# RUN add-apt-repository -y ppa:deadsnakes/ppa && \
#     apt-get update && apt-get install -y --no-install-recommends \
#     python3.12 \
#     python3.12-dev \
#     python3.12-venv \
#     && rm -rf /var/lib/apt/lists/*

RUN python3.12 -m venv /opt/tb-venv
ENV PATH="/opt/tb-venv/bin:${PATH}"

# Keep packaging tools fresh
RUN python -m pip install --upgrade pip setuptools wheel virtualenv

RUN pip install "tensorflow==2.21.0"

# Node.js 16 to stay close to TB frontend tooling in the workflow
# (their lint-frontend job uses setup-node with node-version: 16)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
      gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install -y --no-install-recommends \
      nodejs \
    && npm install -g yarn \
    && rm -rf /var/lib/apt/lists/*

# Bazelisk as /usr/local/bin/bazel.
# Handy for switching versions locally, but you can also pin 7.7.0 with USE_BAZEL_VERSION.
RUN wget -O /usr/local/bin/bazel \
    https://github.com/bazelbuild/bazelisk/releases/download/v1.28.1/bazelisk-linux-amd64 && \
    chmod +x /usr/local/bin/bazel

# Optional but useful for local debugging
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FORCE_COLOR=1

# Default Bazel target version for your local migration work
ENV USE_BAZEL_VERSION=7.7.0

# .bazelrc like in CI
RUN mkdir -p /root && \
    cat <<'EOF' > /root/.bazelrc
build --spawn_strategy=sandboxed
build --worker_sandboxing
build --strategy=CopyFile=local
build --strategy=CopyDirectory=local
build --action_env=PATH
build --verbose_failures
build --worker_verbose
test --test_output=errors
test --test_verbose_timeout_warnings
common --remote_upload_local_results=false
test --remote_upload_local_results=false
test --cache_test_results=false
EOF

WORKDIR /workspace

CMD ["/bin/bash"]

# docker build -t tb-ci-py312 .
# docker run -it tb-ci-py312
# docker system prune -a -f


FROM ubuntu:22.04

SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PIP_ROOT_USER_ACTION=ignore
ENV TF_USE_LEGACY_KERAS=1
ENV VIRTUAL_ENV=/opt/tfqenv
ENV PATH=/opt/tfqenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Match the GH build workflow baseline as closely as practical for local runs:
# Ubuntu 22.04, JDK 17, Python 3.11, and tools needed by scripts/ci_install.sh.
# Docker Desktop occasionally hits transient Ubuntu mirror/network failures, so
# retry the apt phase instead of failing the whole image build on the first hit.
RUN set -eux; \
    sed -i 's|http://archive.ubuntu.com/ubuntu|https://archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list; \
    sed -i 's|http://security.ubuntu.com/ubuntu|https://security.ubuntu.com/ubuntu|g' /etc/apt/sources.list; \
    echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80-retries; \
    echo 'Acquire::http::Timeout "30";' >> /etc/apt/apt.conf.d/80-retries; \
    echo 'Acquire::https::Timeout "30";' >> /etc/apt/apt.conf.d/80-retries; \
    echo 'Acquire::ForceIPv4 "true";' >> /etc/apt/apt.conf.d/80-retries; \
    echo 'Acquire::https::Verify-Peer "false";' > /etc/apt/apt.conf.d/99bootstrap-https; \
    echo 'Acquire::https::Verify-Host "false";' >> /etc/apt/apt.conf.d/99bootstrap-https; \
    for attempt in 1 2 3; do \
      rm -rf /var/lib/apt/lists/* && \
      apt-get update -o APT::Update::Error-Mode=any && \
      apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        clang \
        curl \
        git \
        gnupg \
        lld \
        lsb-release \
        openjdk-17-jdk \
        pkg-config \
        python3-pip \
        sudo \
        unzip \
        wget \
        zlib1g-dev \
        zip && \
      curl -fsSL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xF23C5A6CF475977595C89F51BA6932366A755776' | \
        gpg --dearmor -o /usr/share/keyrings/deadsnakes.gpg && \
      echo 'deb [signed-by=/usr/share/keyrings/deadsnakes.gpg] https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy main' \
        > /etc/apt/sources.list.d/deadsnakes.list && \
      apt-get update -o APT::Update::Error-Mode=any && \
      apt-get install -y --no-install-recommends \
        python3.11 \
        python3.11-dev \
        python3.11-venv && \
      rm -f /etc/apt/apt.conf.d/99bootstrap-https && \
      rm -rf /var/lib/apt/lists/* && \
      break; \
      echo "apt install attempt ${attempt} failed; retrying..." >&2; \
      rm -rf /var/lib/apt/lists/*; \
      sleep 15; \
      if [ "${attempt}" = "3" ]; then \
        exit 1; \
      fi; \
    done

RUN python3.11 -m venv "${VIRTUAL_ENV}" \
 && python -m pip install --upgrade pip setuptools wheel

# Provide Bazel locally for ad hoc runs of scripts like
# scripts/build_pip_package_test.sh. CI still installs Bazel explicitly via
# scripts/ci_install.sh, but having Bazelisk preinstalled makes the container
# much easier to use interactively.
RUN curl -fsSL https://github.com/bazelbuild/bazelisk/releases/download/v1.22.0/bazelisk-linux-amd64 \
      -o /usr/local/bin/bazelisk \
 && chmod +x /usr/local/bin/bazelisk \
 && ln -sf /usr/local/bin/bazelisk /usr/local/bin/bazel

WORKDIR /workspace

CMD ["/bin/bash"]

# ### END DOCKERFILE ###

# docker build -t tfq-ci-build -f shared_files/tfq/218/Dockerfile shared_files/tfq/218
# docker run -it tfq-ci-build
# docker run --rm -it -v "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum_p":/workspace/quantum tfq-ci-build

# Inside the container #

# --------------------------------------------------------------------
# Clone + build + install TFQ
# --------------------------------------------------------------------
# cd /workspace/quantum && \
#     sed -i 's/\r$//' .bazelversion configure.sh release/build_pip_package.sh scripts/*.sh || true && \
#     pip install --no-cache-dir -r requirements.txt && \
#     ./configure.sh --python="$(which python)" && \
#     bazel clean --expunge && \
#     bazel build -c opt \
#       --cxxopt="-O3" --cxxopt="-march=native" --cxxopt="-std=c++17" \
#       --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=1" --linkopt="-fuse-ld=lld" \
#       release:build_pip_package && \
#     bazel-bin/release/build_pip_package /tmp/tfquantum && \
#     pip install --no-cache-dir /tmp/tfquantum/*.whl
# ./scripts/test_all.sh
# ./scripts/ci_validate_tutorials.sh

# --------------------------------------------------------------------
# Quick runtime check (fail-fast during build)
# --------------------------------------------------------------------
# cd /tmp
# python - <<'PY'
# import tensorflow as tf, tensorflow_quantum as tfq, tf_keras as k2, cirq, numpy as np, sympy
# print("TF:", tf.__version__)
# print("TFQ:", tfq.__version__)
# print("tf-keras:", k2.__version__)
# print("Cirq:", cirq.__version__)
# print("NumPy:", np.__version__)
# print("Sympy:", sympy.__version__)
# PY

# Notes or usual commands for local use #

# pip install pip-tools
# pip-compile --upgrade --generate-hashes -o requirements.txt requirements.in

FROM nvidia/cuda:12.8.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

# OS deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git curl wget unzip zip patchelf \
    python3.10 python3.10-dev python3.10-venv python3-pip \
    pkg-config g++ zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Bazel 6.5.0 (required by TFQ w/ TF 2.15)
RUN wget -q https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel_6.5.0-linux-x86_64.deb \
    && dpkg -i bazel_6.5.0-linux-x86_64.deb \
    && apt-mark hold bazel \
    && rm -f bazel_6.5.0-linux-x86_64.deb

# Nice to have
RUN python3 -m pip install --upgrade pip wheel setuptools
WORKDIR /workspace

CMD ["/bin/bash"]

# docker build -t tfq .
# docker run --rm -it -v %CD%:/workspace tfq-src:cpu

# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum" 82f7b6ae239f:/workspace

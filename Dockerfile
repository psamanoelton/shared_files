# Base image
FROM nvidia/cuda:12.8.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Core build deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates gnupg build-essential pkg-config \
    python3 python3-dev python3-venv python3-pip \
    zip unzip libffi-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# --- Add LLVM repo for Jammy and install clang-18 toolchain ---
# RUN mkdir -p /etc/apt/keyrings && \
#     curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key \
#       | tee /etc/apt/keyrings/llvm-snapshot.gpg.key >/dev/null && \
#     echo "deb [signed-by=/etc/apt/keyrings/llvm-snapshot.gpg.key] http://apt.llvm.org/jammy/ llvm-toolchain-jammy-18 main" \
#       > /etc/apt/sources.list.d/llvm.list && \
#     apt-get update && apt-get install -y --no-install-recommends \
#       clang-18 lld-18 llvm-18-tools libc++-18-dev libc++abi-18-dev libunwind-18-dev && \
#     update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100 && \
#     update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100 && \
#     update-alternatives --install /usr/bin/lld lld /usr/bin/lld-18 100 && \
#     rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key \
      -o /etc/apt/keyrings/llvm-snapshot.gpg.key && \
    echo "deb [signed-by=/etc/apt/keyrings/llvm-snapshot.gpg.key] http://apt.llvm.org/jammy/ llvm-toolchain-jammy-19 main" \
      > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && apt-get install -y --no-install-recommends \
      clang-19 lld-19 llvm-19-tools && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-19 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-19 100 && \
    update-alternatives --install /usr/bin/lld lld /usr/bin/lld-19 100 && \
    rm -rf /var/lib/apt/lists/*
ENV CLANG_CUDA_COMPILER_PATH=/usr/lib/llvm-19/bin/clang

# Bazelisk
RUN curl -L https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 \
      -o /usr/local/bin/bazel && chmod +x /usr/local/bin/bazel

# Python
RUN python3 -m pip install -U pip setuptools wheel numpy

# TensorFlow 2.20
WORKDIR /workspace
RUN git clone https://github.com/tensorflow/tensorflow.git && \
    cd tensorflow && git checkout v2.20.0
WORKDIR /workspace/tensorflow

# Configure for CUDA + CC 12.0 (sm_120) and hermetic CUDA 12.8.1 + cuDNN 9.8
ENV TF_NEED_CUDA=1 \
    TF_CUDA_COMPUTE_CAPABILITIES=12.0 \
    TF_NEED_ROCM=0 \
    CC_OPT_FLAGS="-march=x86-64-v3" \
    PYTHON_BIN_PATH=/usr/bin/python3 \
    # Tell TF's CUDA rules to use hermetic CUDA/cuDNN and target compute_120
    HERMETIC_CUDA_VERSION=12.8.1 \
    HERMETIC_CUDNN_VERSION=9.8.0 \
    HERMETIC_CUDA_COMPUTE_CAPABILITIES=compute_120 \
    # Prefer clang toolchain in the environment
    CC=clang CXX=clang++

# Generate .tf_configure.bazelrc
RUN yes "" | ./configure

CMD ["/bin/bash"]


# one-off build that will JIT at runtime on the RTX Pro 6000:
# bazel clean --expunge
# bazel build //tensorflow/tools/pip_package:wheel \
#   --config=opt \
#   --config=cuda \
#   --config=cuda_clang \
#   --@local_config_cuda//cuda:override_include_cuda_libs=true \
#   --repo_env=HERMETIC_CUDA_VERSION=12.8.1 \
#   --repo_env=HERMETIC_CUDNN_VERSION=9.8.0 \
#   --repo_env=HERMETIC_CUDA_COMPUTE_CAPABILITIES=compute_90 \
#   --repo_env=HERMETIC_PYTHON_VERSION=3.12 \
#   --linkopt=-fuse-ld=lld \
#   --verbose_failures

# Base image
FROM nvidia/cuda:12.8.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

# -------------------------------------------------------------------
# Core build deps + tools we need for Miniconda
# -------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates gnupg build-essential pkg-config \
    python3 python3-dev python3-venv python3-pip \
    zip unzip libffi-dev libssl-dev wget bzip2 \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------------------
# (Optional) LLVM 19 — fine to keep for host compilation,
# but TF build will use NVCC, not clang
# -------------------------------------------------------------------
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
# (Do not export CLANG_CUDA_COMPILER_PATH; we want NVCC for CUDA)

# -------------------------------------------------------------------
# Bazelisk (will pick the Bazel version from .bazelversion in TF repo)
# -------------------------------------------------------------------
RUN curl -L https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 \
      -o /usr/local/bin/bazel && chmod +x /usr/local/bin/bazel

# -------------------------------------------------------------------
# Miniconda + Python 3.12 env (tf312) and accept Anaconda repo TOS
# -------------------------------------------------------------------
ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:$PATH

RUN wget -O /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash /tmp/miniconda.sh -b -p ${CONDA_DIR} && \
    rm -f /tmp/miniconda.sh && \
    conda config --set always_yes yes --set changeps1 no && \
    # Accept TOS for default channels
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
    conda clean -a -y

# Create the Python 3.12 env for runtime/tests and auto-activate it on login
RUN conda create -y -n tf312 python=3.12 && \
    echo "source ${CONDA_DIR}/etc/profile.d/conda.sh && conda activate tf312" >> /root/.bashrc

# Use the env's Python for TF build
ENV PYTHON_BIN_PATH=${CONDA_DIR}/envs/tf312/bin/python

# Make sure base tools (in the tf312 env) are current
RUN ${PYTHON_BIN_PATH} -m pip install -U pip setuptools wheel numpy

# -------------------------------------------------------------------
# TensorFlow 2.20.0 (release tag)
# -------------------------------------------------------------------
WORKDIR /workspace
RUN git clone https://github.com/tensorflow/tensorflow.git && \
    cd tensorflow && git checkout v2.20.0
WORKDIR /workspace/tensorflow

# -------------------------------------------------------------------
# Configure for CUDA + Blackwell CC 12.0 (sm_120) and hermetic CUDA 12.8.1 + cuDNN 9.8
# -------------------------------------------------------------------
ENV TF_NEED_CUDA=1 \
    TF_NEED_ROCM=0 \
    TF_CUDA_COMPUTE_CAPABILITIES=12.0 \
    CC_OPT_FLAGS="-march=x86-64-v3" \
    HERMETIC_CUDA_VERSION=12.8.1 \
    HERMETIC_CUDNN_VERSION=9.8.0 \
    HERMETIC_CUDA_COMPUTE_CAPABILITIES=compute_120 \
    HERMETIC_PYTHON_VERSION=3.12

# Run ./configure non-interactively (it will use $PYTHON_BIN_PATH)
RUN yes "" | ./configure

# -------------------------------------------------------------------
# Force NVCC (not clang) + expose CUDA stub for Bazel genrules
# -------------------------------------------------------------------

# 1) Force TF/Bazel to use NVCC as the CUDA compiler by default
#    (append to .tf_configure.bazelrc; also strip any accidental cuda_clang bits)
RUN sed -i '/cuda_clang/d' .tf_configure.bazelrc && \
    sed -i '/CLANG_CUDA_COMPILER_PATH/d' .tf_configure.bazelrc && \
    printf '\n# Force CUDA toolchain to NVCC by default\nbuild --@local_config_cuda//:cuda_compiler=nvcc\n' >> .tf_configure.bazelrc

# 2) Add CUDA stub and expose to Bazel (so genrules can dlopen libcuda.so.1)
RUN ln -sf /usr/local/cuda/targets/x86_64-linux/lib/stubs/libcuda.so \
           /usr/local/cuda/targets/x86_64-linux/lib/stubs/libcuda.so.1

ENV LD_LIBRARY_PATH=/usr/local/cuda/targets/x86_64-linux/lib/stubs:/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

# Keep workdir
WORKDIR /workspace/tensorflow

# Default to an interactive shell
CMD ["/bin/bash"]


# Example build inside the container:

# bazel clean --expunge

bazel build //tensorflow/tools/pip_package:wheel \
  --config=opt \
  --config=cuda \
  --@local_config_cuda//:cuda_compiler=nvcc \
  --@local_config_cuda//cuda:override_include_cuda_libs=true \
  --repo_env=HERMETIC_CUDA_VERSION=12.8.1 \
  --repo_env=HERMETIC_CUDNN_VERSION=9.8.0 \
  --repo_env=HERMETIC_CUDA_COMPUTE_CAPABILITIES=compute_120 \
  --repo_env=HERMETIC_PYTHON_VERSION=3.12 \
  --action_env=LD_LIBRARY_PATH \
  --verbose_failures

# Wheel ends up at something like:
#   bazel-bin/tensorflow/tools/pip_package/wheel_house/\
#     tensorflow-2.20.0+selfbuilt-cp312-cp312-linux_x86_64.whl



# # To build this image, run:
# #    docker build -t tf220 .

# # To run this image, run:
# #   docker run -it tf220

# # To remove the image, run:
# #   docker rm -f tf220

# Re open the image
# #   docker exec -it 494b8152e3cd /bin/bash

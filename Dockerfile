# ==========================================================
# TensorFlow 2.20.0 built from source for Compute Capability 12.0
# Base: Ubuntu 24.04 + CUDA 12.9.1 + cuDNN 9.8.0 + LLVM 20 + Bazel 6.5.0
# Target GPU: NVIDIA RTX PRO 6000 (Blackwell, sm_120)
# ==========================================================

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# ----------------------------------------------------------
# Install Python 3.12 (system), but install pip only inside venv
# ----------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl git gnupg2 ca-certificates unzip zip \
    build-essential software-properties-common pkg-config \
    libffi-dev libssl-dev zlib1g-dev libjpeg-dev libpng-dev \
    python3.12 python3.12-venv python3.12-dev && \
    ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------
# Create isolated Python 3.12 virtual environment (PEP 668-safe)
# ----------------------------------------------------------
RUN python3.12 -m venv /opt/tf && \
    /opt/tf/bin/python -m ensurepip && \
    /opt/tf/bin/pip install --upgrade pip setuptools wheel numpy

ENV PATH=/opt/tf/bin:${PATH}
ENV PYTHON_BIN_PATH=/opt/tf/bin/python
ENV PYTHON_LIB_PATH=/opt/tf/lib/python3.12/site-packages

# ----------------------------------------------------------
# Install CUDA Toolkit 12.9.1
# ----------------------------------------------------------
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-ubuntu2404.pin && \
    mv cuda-ubuntu2404.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    wget https://developer.download.nvidia.com/compute/cuda/12.9.1/local_installers/cuda-repo-ubuntu2404-12-9-local_12.9.1-575.57.08-1_amd64.deb && \
    dpkg -i cuda-repo-ubuntu2404-12-9-local_12.9.1-575.57.08-1_amd64.deb && \
    cp /var/cuda-repo-ubuntu2404-12-9-local/cuda-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update && apt-get install -y cuda-toolkit-12-9 && \
    rm -rf /var/lib/apt/lists/* && \
    export PATH=/usr/local/cuda/bin:${PATH} && \
    export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}
# ENV PATH=/usr/local/cuda/bin:${PATH}
# ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

# # ----------------------------------------------------------
# # Install NVIDIA Open Driver (optional for inside-container testing)
# # (In production, rely on host driver + --gpus all)
# # ----------------------------------------------------------
RUN apt-get update && apt-get install -y nvidia-open && rm -rf /var/lib/apt/lists/*

# # ----------------------------------------------------------
# # Install cuDNN 9.8.0
# # ----------------------------------------------------------
RUN wget https://developer.download.nvidia.com/compute/cudnn/9.8.0/local_installers/cudnn-local-repo-ubuntu2404-9.8.0_1.0-1_amd64.deb && \
    dpkg -i cudnn-local-repo-ubuntu2404-9.8.0_1.0-1_amd64.deb && \
    cp /var/cudnn-local-repo-ubuntu2404-9.8.0/cudnn-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update && apt-get install -y cudnn cudnn-cuda-12 && \
    rm -rf /var/lib/apt/lists/*
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

# # ----------------------------------------------------------
# # Install Bazel 6.5.0 (for TensorFlow 2.19–2.20)
# # ----------------------------------------------------------
RUN apt-get update && apt-get install -y g++ unzip && \
    wget https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-installer-linux-x86_64.sh && \
    chmod +x bazel-6.5.0-installer-linux-x86_64.sh && ./bazel-6.5.0-installer-linux-x86_64.sh && \
    rm bazel-6.5.0-installer-linux-x86_64.sh && \
    rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------
# Install Bazel 7.4.1 (for TensorFlow 2.20)
# ----------------------------------------------------------
RUN apt-get update && apt-get install -y g++ unzip && \
    wget https://github.com/bazelbuild/bazel/releases/download/7.4.1/bazel-7.4.1-installer-linux-x86_64.sh && \
    chmod +x bazel-7.4.1-installer-linux-x86_64.sh && ./bazel-7.4.1-installer-linux-x86_64.sh && \
    rm bazel-7.4.1-installer-linux-x86_64.sh && \
    rm -rf /var/lib/apt/lists/*

# # ----------------------------------------------------------
# # Install LLVM 20
# # ----------------------------------------------------------
RUN wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && ./llvm.sh 20 && rm llvm.sh
ENV CC=/usr/lib/llvm-20/bin/clang
ENV CXX=/usr/lib/llvm-20/bin/clang++

# ----------------------------------------------------------
# Clone TensorFlow and configure build
# ----------------------------------------------------------
WORKDIR /workspace
RUN git clone https://github.com/tensorflow/tensorflow.git && cd tensorflow && git checkout r2.20

WORKDIR /workspace/tensorflow

# ----------------------------------------------------------
# Define all TensorFlow build environment vars (skip ./configure)
# ----------------------------------------------------------
# ENV TF_NEED_CUDA=1
# ENV TF_CUDA_VERSION=12.9
# ENV TF_CUDNN_VERSION=9.8
# ENV HERMETIC_CUDA_VERSION=12.9
# ENV HERMETIC_CUDNN_VERSION=9.8
# ENV TF_CUDA_COMPUTE_CAPABILITIES=12.0
# ENV HERMETIC_PYTHON_VERSION=3.12
# ENV TF_CUDA_PATHS=/usr/local/cuda,/usr/lib/x86_64-linux-gnu
# ENV TF_CUDA_CLANG=1
# ENV TF_ENABLE_XLA=1
# ENV LOCAL_CUDA_PATH=/usr/local/cuda
# ENV GCC_HOST_COMPILER_PATH=/usr/lib/llvm-20/bin/clang
# ENV CLANG_CUDA_COMPILER_PATH=/usr/lib/llvm-20/bin/clang

# export TF_NEED_CUDA=1
# export TF_CUDA_VERSION=12.9
# export TF_CUDNN_VERSION=9.8.0
# export HERMETIC_CUDA_VERSION=12.8.1
# export HERMETIC_CUDNN_VERSION=9.8
# export TF_CUDA_COMPUTE_CAPABILITIES=12.0
# export HERMETIC_PYTHON_VERSION=3.12
# export TF_CUDA_PATHS=/usr/local/cuda,/usr/lib/x86_64-linux-gnu
# export TF_CUDA_CLANG=1
# export TF_ENABLE_XLA=1
# export LOCAL_CUDA_PATH=/usr/local/cuda
# export GCC_HOST_COMPILER_PATH=/usr/lib/llvm-20/bin/clang
# export CLANG_CUDA_COMPILER_PATH=/usr/lib/llvm-20/bin/clang

# # sed -i 's/12\.9/12.8.1/g' /workspace/tensorflow/.tf_configure.bazelrc
# # grep HERMETIC_CUDA_VERSION /workspace/tensorflow/.tf_configure.bazelrc
# # --repo_env HERMETIC_CUDA_VERSION=12.8.1


# # # ----------------------------------------------------------
# # # Build TensorFlow wheel
# # # ----------------------------------------------------------
# bazel build //tensorflow/tools/pip_package:wheel \
#   --repo_env=USE_PYWRAP_RULES=1 \
#   --repo_env=WHEEL_NAME=tensorflow \
#   --config=cuda --config=cuda_clang

# # # Build the pip wheel
# # RUN ./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
# #     pip install /tmp/tensorflow_pkg/tensorflow-*.whl

# # # ----------------------------------------------------------
# # # Test TensorFlow GPU availability
# # # ----------------------------------------------------------
# # RUN python3 -c "import tensorflow as tf; print('Num GPUs available:', len(tf.config.list_physical_devices('GPU'))); print('TF built with CUDA:', tf.test.is_built_with_cuda())"

# CMD ["/bin/bash"]

# # To build this image, run:
# #    docker build -t tf220 .
# #    docker build -t tf220 . > build_tf220.log 2>&1

# # LOGFILE="build_$(date +'%Y%m%d_%H%M%S').log"
# # docker build -t tf220 . 2>&1 | tee "$LOGFILE"


# # To run this image, run:
# #   docker run -it  tf220

# # To remove the image, run:
# #   docker rm -f tf220

# # 1f4ee8bcd86b7333e9a98f666d70309fc7c8907a

# bazel build //tensorflow/tools/pip_package:wheel --repo_env=USE_PYWRAP_RULES=1 --repo_env=WHEEL_NAME=tensorflow --config=cuda --config=cuda_wheel

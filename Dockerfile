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
    rm -rf /var/lib/apt/lists/*
ENV PATH=/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

# # ----------------------------------------------------------
# # Install NVIDIA Open Driver (optional for inside-container testing)
# # (In production, rely on host driver + --gpus all)
# # ----------------------------------------------------------
RUN apt-get update && apt-get install -y nvidia-open-driver && rm -rf /var/lib/apt/lists/*

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

# # Create .tf_configure.bazelrc for compute capability 12.0
# RUN echo 'build --action_env PYTHON_BIN_PATH="/opt/tf/bin/python3"' > .tf_configure.bazelrc && \
#     echo 'build --action_env PYTHON_LIB_PATH="/opt/tf/lib/python3.12/site-packages"' >> .tf_configure.bazelrc && \
#     echo 'build --python_path="/opt/tf/bin/python3"' >> .tf_configure.bazelrc && \
#     echo 'build:cuda --repo_env HERMETIC_CUDA_VERSION="12.9"' >> .tf_configure.bazelrc && \
#     echo 'build:cuda --repo_env HERMETIC_CUDNN_VERSION="9.8"' >> .tf_configure.bazelrc && \
#     echo 'build:cuda --repo_env HERMETIC_CUDA_COMPUTE_CAPABILITIES="12.0"' >> .tf_configure.bazelrc && \
#     echo 'build:cuda --repo_env LOCAL_CUDA_PATH="/usr/local/cuda/lib64"' >> .tf_configure.bazelrc && \
#     echo 'build --config=cuda_clang' >> .tf_configure.bazelrc && \
#     echo 'build --action_env CLANG_CUDA_COMPILER_PATH="/usr/lib/llvm-20/bin/clang"' >> .tf_configure.bazelrc && \
#     echo 'build:opt --copt=-Wno-sign-compare' >> .tf_configure.bazelrc && \
#     echo 'build:opt --host_copt=-Wno-sign-compare' >> .tf_configure.bazelrc

# # Configure TensorFlow
# RUN yes "" | ./configure

# # ----------------------------------------------------------
# # Build TensorFlow wheel
# # ----------------------------------------------------------
# RUN bazel build //tensorflow/tools/pip_package:build_pip_package \
#     --repo_env=USE_PYWRAP_RULES=1 \
#     --config=cuda --config=cuda_clang \
#     --jobs=8

# # Build the pip wheel
# RUN ./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
#     pip install /tmp/tensorflow_pkg/tensorflow-*.whl

# # ----------------------------------------------------------
# # Test TensorFlow GPU availability
# # ----------------------------------------------------------
# RUN python3 -c "import tensorflow as tf; print('Num GPUs available:', len(tf.config.list_physical_devices('GPU'))); print('TF built with CUDA:', tf.test.is_built_with_cuda())"

CMD ["/bin/bash"]

# To build this image, run:
#    docker build -t tf220 .

# To run this image, run:
#   docker run -it --name tf220 tf220

# To remove the image, run:
#   docker rm -f tf220


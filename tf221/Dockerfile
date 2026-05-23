FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

# ---- System deps ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    pkg-config \
    dos2unix \
    python3-dev \
    python3-pip \
    lsb-release \
    wget \
    software-properties-common \
    gnupg \
    patchelf \
    xxd \
    vim \
    && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y \
    python3.14 \
    python3.14-dev \
    python3.14-venv \
    && rm -rf /var/lib/apt/lists/*

RUN python3.14 -m venv 314-venv
ENV PATH="/314-venv/bin:${PATH}"
# source /opt/venv/bin/activate

RUN pip install -U pip numpy wheel packaging requests six

# Install Bazel
RUN wget -L https://github.com/bazelbuild/bazelisk/releases/download/v1.28.1/bazelisk-linux-amd64 -O /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

# ---- LLVM/Clang 20 (recommended by TF docs) ----w
RUN wget -qO- https://apt.llvm.org/llvm.sh | bash -s -- 20 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone TF 2.21
RUN git clone https://github.com/psamanoelton/tensorflow.git
WORKDIR /tensorflow

# ./configure
# /usr/bin/clang-20
# bazel build //tensorflow/tools/pip_package:wheel --repo_env=USE_PYWRAP_RULES=1 --repo_env=WHEEL_NAME=tensorflow_cpu

# pip install bazel-bin/tensorflow/tools/pip_package/wheel_house/tensorflow_cpu-2.22.0.dev0+selfbuilt-cp314-cp314-linux_x86_64.whl

bazel test --test_output=errors --cache_test_results=no --repo_env=HERMETIC_PYTHON_VERSION=3.14 -k \
    //tensorflow/tools/compatibility/... \
    //tensorflow/tools/api/tests/... \
    //tensorflow/python/...

bazel test --test_output=errors --cache_test_results=no --repo_env=HERMETIC_PYTHON_VERSION=3.14 -k \
    //tensorflow/tools/compatibility:tf_upgrade_test \
    //tensorflow/tools/compatibility:tf_upgrade_v2_safety_test \
    //tensorflow/python/checkpoint:checkpoint_test \
    //tensorflow/python/framework:extension_type_test \
    //tensorflow/python/framework:extension_type_field_test \
    //tensorflow/python/framework:test_util_test_cpu \
    //tensorflow/python/kernel_tests/nn_ops:betainc_op_test_cpu \
    //tensorflow/tools/api/tests:module_test


# ### END DOCKERFILE ###



# docker build -t tf-tf:221 .
# docker run -it tf-tf:221
# docker exec -it 2c1aa22ae7ab /bin/bash

# docker system prune -a -f


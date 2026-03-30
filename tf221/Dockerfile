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
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    && rm -rf /var/lib/apt/lists/*

RUN python3.12 -m venv 312-venv
ENV PATH="/312-venv/bin:${PATH}"
# source /opt/venv/bin/activate

RUN pip install -U pip numpy wheel packaging requests six

# Install Bazel
RUN wget -L https://github.com/bazelbuild/bazelisk/releases/download/v1.28.1/bazelisk-linux-amd64 -O /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

# ---- LLVM/Clang 20 (recommended by TF docs) ----w
RUN wget -qO- https://apt.llvm.org/llvm.sh | bash -s -- 20 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone TF 2.21
RUN git clone https://github.com/tensorflow/tensorboard.git --depth 3 --branch 2.21
WORKDIR /tensorboard

# ./configure
# /usr/bin/clang-20
# bazel build //tensorflow/tools/pip_package:wheel --repo_env=USE_PYWRAP_RULES=1 --repo_env=WHEEL_NAME=tensorflow_cpu

# pip install bazel-bin/tensorflow/tools/pip_package/wheel_house/tensorflow_cpu-2.21.0rc0-cp312-cp312-linux_x86_64.whl

# bazel test --test_output=errors //tensorflow/python/framework:constant_op_test //tensorflow/python/ops:math_ops_test //tensorflow/python/eager:context_test

# ### END DOCKERFILE ###`



# docker build -t tf-tf:221 .
# docker run -it tf-tf:221
# docker exec -it 2c1aa22ae7ab /bin/bash

# docker system prune -a -f


# # source .venv/bin/activate

# # pip install -r requirements.txt
# # ./configure.sh
# # ./configure.sh --python="$ABS_PY"
# # bazel build -c opt --cxxopt="-O3" --cxxopt="-march=native" --cxxopt="-std=c++17" --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=1" release:build_pip_package
# # bazel-bin/release/build_pip_package /tmp/tfquantum/
# # python3 -m pip install /tmp/tfquantum/name_of_generated_wheel.whl

# # # $src = "C:\Users\Pablo Samano\Desktop\Rivian\google"   # change to your path
# # # docker run --rm -it --name tfqq --mount type=bind,source="$src",target=/workspace tfqn /bin/bash

# # docker run --rm -it --name tfq -v "C:\Users\Pablo Samano\Desktop\Rivian\google":/workspace tfq-tf216:latest

# docker run --rm -it --name tfqn -v "C:\Users\Pablo Samano\Desktop\Rivian\google":/workspace tfq-tf216:latest


# # docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\tensorflow" 47140e0ef6cd:/workspace
# # docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum" a05debad652a:/workspace

# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum_p\release\build_pip_package.sh" ea2ae16ac6f4:/workspace/quantum/bazel-bin/release/


# ### END 2 END ###
# # choose your env
# python3.11 -m venv .venv && . .venv/bin/activate
# pip install -U pip
# pip install tensorflow==2.16.2 tf-keras==2.16.0 numpy==1.26.4 \
#             sympy==1.14.0 protobuf>=4.25,<5 cirq-core==1.3.* cirq-google==1.3.*

# # reconfigure with your venv python
# ./configure.sh --python="$(pwd)/.venv/bin/python"

# # make sure Windows line-endings didn’t sneak in
# sed -i 's/\r$//' release/build_pip_package.sh scripts/*.sh configure.sh || true
# chmod +x release/build_pip_package.sh scripts/*.sh configure.sh

# # clean & build
# bazel clean --expunge
# bazel build -c opt \
#   --cxxopt="-O3" --cxxopt="-march=native" --cxxopt="-std=c++17" \
#   --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=1" --linkopt="-fuse-ld=lld" \
#   release:build_pip_package

# # build the wheel with the same interpreter (thanks to our build_pip_package.sh patch)
# bazel-bin/release/build_pip_package /tmp/tfquantum

# pip install /tmp/tfquantum/*.whl

# # sanity
# python - <<'PY'
# import tensorflow as tf, tensorflow_quantum as tfq, tf_keras as k2, cirq, numpy as np, sympy
# print("TF:", tf.__version__)
# print("TFQ:", tfq.__version__)
# print("tf-keras:", k2.__version__)
# print("Cirq:", cirq.__version__)
# print("NumPy:", np.__version__)
# print("Sympy:", sympy.__version__)
# PY

# ###





# # sed -i 's/\r$//' bazel-bin/release/build_pip_package
# # bazel-bin/release/build_pip_package /tmp/tfquantum
# # sed -i 's/\bpython3\b/python3.11/g' bazel-bin/release/build_pip_package
# # bazel-bin/release/build_pip_package /tmp/tfquantum
# # pip install /tmp/tfquantum/*.whl

# cd /workspace
# python3.11 - <<'PY'
# import tensorflow as tf, tensorflow_quantum as tfq, cirq, numpy as np, google.protobuf as gp, sympy
# print("TF:", tf.__version__)
# print("TFQ:", tfq.__version__)
# print("Cirq:", cirq.__version__)
# print("NumPy:", np.__version__)
# print("Protobuf:", gp.__version__)
# print("sympy:", sympy.__version__)
# print("tfq from:", tfq.__file__)
# PY

# # sed -i 's/\r$//' scripts/test_all.sh
# # ./scripts/test_all.sh

# git clone https://github.com/psamanoelton/quantum.git
# cd quantum
# git checkout feature/tf216_support

# conda activate tfq

# pip install -r requirements.txt

# ./configure.sh --python="$(which python3.11)"
# bazel clean --expunge
# bazel build -c opt \
#   --cxxopt="-O3" --cxxopt="-march=native" --cxxopt="-std=c++17" \
#   --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=1" --linkopt="-fuse-ld=lld" \
#   release:build_pip_package

# bazel-bin/release/build_pip_package /tmp/tfquantum
# pip install /tmp/tfquantum/*.whl

############ TODO ############

# This will be needed when TFQ 2.20 is released

# Fix pip package to properly use TFQ with pip install
# Fix Google Colab TFQ install (enable TFQ in Google Colab)
# Update Devsite
# Update README
# Update TFQ Install instructions / Provide same steps as TF Install instructions

# ############ TODO ############
# cd ..
# python - <<'PY'
# import tensorflow as tf, tensorflow_quantum as tfq, tf_keras as k2, cirq, numpy as np, sympy
# print("TF:", tf.__version__)
# print("TFQ:", tfq.__version__)
# print("tf-keras:", k2.__version__)
# print("Cirq:", cirq.__version__)
# print("NumPy:", np.__version__)
# print("Sympy:", sympy.__version__)
# PY

# conda activate tfq
# cd quantum

# git clone https://github.com/psamanoelton/quantum.git && \
#     cd quantum && \
#     git checkout feature/tf218_support && \
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

# rm scripts/test_tutorials.py
# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum_p\scripts\test_tutorials.py" f719201a63fb:/workspace/quantum/scripts/test_tutorials.py

# rm scripts/ci_validate_tutorials.sh
# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum_p\scripts\ci_validate_tutorials.sh" f719201a63fb:/workspace/quantum/scripts/ci_validate_tutorials.sh
# sed -i 's/\r$//' /workspace/quantum/scripts/ci_validate_tutorials.sh

# rm configure.sh
# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum_p\configure.sh" f719201a63fb:/workspace/quantum/configure.sh
# sed -i 's/\r$//' /tensorflow/configure

# rm release/build_pip_package.sh
# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum_p\release\build_pip_package.sh" f719201a63fb:/workspace/quantum/release/build_pip_package.sh

# rm WORKSPACE
# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum_p\WORKSPACE" f719201a63fb:/workspace/quantum/WORKSPACE
# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum\release\setup.py" 2c1aa22ae7ab:/workspace/quantum/release/setup.py
# C:\Users\Pablo Samano\Desktop\Rivian\google\quantum\release\setup.py


# rm release/setup.py
# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum_17" f248539d39fd:/workspace/quantum

# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum_17" f248539d39fd:/workspace/quantum
# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum_17\WORKSPACE" f248539d39fd:/workspace/quantum/WORKSPACE
# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum_17\requirements.in" f248539d39fd:/workspace/quantum/requirements.in

# C:\Users\Pablo Samano\Desktop\Rivian\google\quantum_17\release\setup.py


# pylint -v scripts/test_tutorials.py tensorflow_quantum/__init__.py |& tee ./pylint.out

# python -m yapf --style=google -i ^
#   release\setup.py scripts\test_tutorials.py tensorflow_quantum\__init__.py

# pip install pip-tools
# pip-compile --upgrade --generate-hashes -o requirements.txt requirements.in


# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\tensorflow" 9a1117477fdd:/

#### Conda refresh env ###

# conda activate base
# conda env remove --name tfq -y
# conda create --name tfq python=3.10 -y
# conda activate tfq


# 3.11
# conda activate base
# conda create --name tfq311 python=3.11 -y
# conda activate tfq311
# bazel clean --expunge
# rm -rf /tmp/tfquantum

# # 3.12
# conda activate base
# conda create --name tfq312 python=3.12 -y
# conda activate tfq312
# bazel clean --expunge
# rm -rf /tmp/tfquantum

# 2-3 Goals

# Learning goals can be 1 single goal


# Project Delivery Goals (Client Tools)

# Productivity 20-30 questions to help me to fillout this section
# Fill out this section



# 'C:\Users\Pablo Samano\Desktop\Rivian\google'


# docker cp 6bb32bf12801:/tensorflow/tensorflow/tools/api/golden 'C:\Users\Pablo Samano\Desktop\Rivian\google'

# C:\Users\Pablo Samano\Desktop\Rivian\google\tensorflow_p\tensorflow\tools\api\golden




# vim ci/official/requirements_updater/requirements.in
# cat ci/official/requirements_updater/requirements.in


# vim tensorflow/tools/pip_package/setup.py.tpl
# cat tensorflow/tools/pip_package/setup.py.tpl

# bazel run //ci/official/requirements_updater:requirements.update --repo_env=HERMETIC_PYTHON_VERSION=3.12

# bazel test //tensorflow/tools/api/tests:api_compatibility_test --repo_env=HERMETIC_PYTHON_VERSION=3.12



# bazel test --test_output=errors --cache_test_results=no //tensorflow/python/summary:summary_test \
# //tensorflow/python/summary:summary_v2_test \
# //tensorflow/python/tpu:tpu_outside_compilation_test

# docker cp c3b8b046271c:/root/.cache/bazel/_bazel_root/68a62076e91007a7908bc42a32e4cff9/execroot/org_tensorflow/bazel-out/k8-opt/testlogs/tensorflow/python/tpu/tpu_outside_compilation_test/test.log tpu_outside_compilation_test.log



# bazel test --test_output=errors --cache_test_results=no \
#   --repo_env=USE_PYWRAP_RULES=False \
#   //tensorflow/python/summary:summary_test \
#   //tensorflow/python/summary:summary_v2_test \
#   //tensorflow/python/tpu:tpu_outside_compilation_test




# rm /tensorflow/tensorflow/python/tpu/BUILD

# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\tensorflow_p\tensorflow\python\tpu\BUILD" c3b8b046271c:/tensorflow/tensorflow/python/tpu/BUILD


# rm /tensorflow/tensorflow/python/tpu/tpu.bzl
# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\tensorflow_p\tensorflow\python\tpu\tpu.bzl" c3b8b046271c:/tensorflow/tensorflow/python/tpu/tpu.bzl



# TensorBoard #
# git clone https://github.com/tensorflow/tensorboard.git --depth 3 --branch 2.21

# pip install --upgrade pip
# pip install tf-nightly -r tensorboard/pip_package/requirements.txt -r tensorboard/pip_package/requirements_dev.txt
# pip uninstall -y tb-nightly

# # This fix: Setuptools v82.0.0 has removed pkg_resources, which is used by tensorflow
# pip install setuptools==81.0.0

# bazel build //tensorboard/pip_package:build_pip_package bazel-bin/tensorboard/pip_package/build_pip_package
# pip install tensorboard-2.20.0-py3-none-any.whl

# # tensorboard executable:
# -mkdir /tensorboard/logs
# ./bazel-bin/tensorboard/tensorboard --logdir /tensorboard/logs


# Go
# Kubernetes containers
# AWS
# React Typescript
# Cursor
# CloudCode
# Python
# Javascript - Typescript
# Lambdas






# Base image
FROM nvidia/cuda:12.8.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

# Core build deps + tools we need for Miniconda
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates gnupg build-essential pkg-config \
    python3 python3-dev python3-venv python3-pip \
    zip unzip libffi-dev libssl-dev wget bzip2 \
    && rm -rf /var/lib/apt/lists/*

# (Optional) LLVM 19 — fine to keep for host compilation, but TF build will use NVCC, not clang
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

# Bazelisk
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
    # Accept TOS for default channels (as you saw in the interactive step)
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
    conda clean -a -y

# Create the Python 3.11 env for runtime/tests and auto-activate it on login
RUN conda create -y -n tf312 python=3.12 && \
    echo "source ${CONDA_DIR}/etc/profile.d/conda.sh && conda activate tf312" >> /root/.bashrc

# Make sure base tools are current
RUN python3 -m pip install -U pip setuptools wheel numpy

# -------------------------------------------------------------------
# TensorFlow (2.21 nightly commit used here)
# -------------------------------------------------------------------
WORKDIR /workspace
RUN git clone https://github.com/tensorflow/tensorflow.git && \
    cd tensorflow && git checkout 735467e89ccfd7ace190363412bb5698164628b5
WORKDIR /workspace/tensorflow

# Configure for CUDA + CC 12.0 (sm_120) and hermetic CUDA 12.8.1 + cuDNN 9.8
ENV TF_NEED_CUDA=1 \
    TF_NEED_ROCM=0 \
    TF_CUDA_COMPUTE_CAPABILITIES=12.0 \
    CC_OPT_FLAGS="-march=x86-64-v3" \
    PYTHON_BIN_PATH=/usr/bin/python3 \
    HERMETIC_CUDA_VERSION=12.8.1 \
    HERMETIC_CUDNN_VERSION=9.8.0 \
    HERMETIC_CUDA_COMPUTE_CAPABILITIES=compute_120

# Run ./configure non-interactively
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

# -------------------------------------------------------------------
# (3) Clean + build with NVCC and Blackwell (12.0) PTX — example only
#
# bazel clean --expunge

# bazel build //tensorflow/tools/pip_package:wheel \
# --config=opt \
# --config=cuda \
# --@local_config_cuda//:cuda_compiler=nvcc \
# --@local_config_cuda//cuda:override_include_cuda_libs=true \
# --repo_env=HERMETIC_CUDA_VERSION=12.8.1 \
# --repo_env=HERMETIC_CUDNN_VERSION=9.8.0 \
# --repo_env=HERMETIC_CUDA_COMPUTE_CAPABILITIES=compute_120 \
# --repo_env=HERMETIC_PYTHON_VERSION=3.12 \
# --action_env=LD_LIBRARY_PATH \
# --verbose_failures
#
# Wheel ends up at:
#   bazel-bin/tensorflow/tools/pip_package/wheel_house/tensorflow-2.21.0.dev0+selfbuilt-cp312-cp312-linux_x86_64.whl
# -------------------------------------------------------------------


# # To build this image, run:
# #    docker build -t tf221 .

# # To run this image, run:
# #   docker run -it tf221

# # To remove the image, run:
# #   docker rm -f tf221

# Re open the image
# #  docker exec -it 0d2f15258eb4 /bin/bash

# conda create -y -n tf312 python=3.12
# conda activate tf312

# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\tensorflow-2.21.0.dev0+selfbuilt-cp312-cp312-linux_x86_64.whl" 0d2f15258eb4:/workspace
# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\tensorflow-2.21.0.dev0+selfbuilt-cp312-cp312-linux_x86_64.whl-0.params" 0d2f15258eb4:/workspace
# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\shared_files\check.py" 0d2f15258eb4:/workspace


# pip install bazel-bin/tensorflow/tools/pip_package/wheel_house/tensorflow-2.21.0.dev0+selfbuilt-cp312-cp312-linux_x86_64.whl

# python -c "import tensorflow as tf; print(tf.__version__)"


# # 1) Match the redists TF linked against
# pip install --no-cache-dir \
#   "nvidia-cudnn-cu12==9.8.0.87" \
#   "nvidia-nvshmem-cu12==3.2.5" \
#   "nvidia-nccl-cu12==2.27.7"

# # 2) Pointers to their lib dirs
# export CUDNN_LIB_DIR="$CONDA_PREFIX/lib/python3.12/site-packages/nvidia/cudnn/lib"
# export NVSHMEM_LIB_DIR="$CONDA_PREFIX/lib/python3.12/site-packages/nvidia/nvshmem/lib"
# export NCCL_LIB_DIR="$CONDA_PREFIX/lib/python3.12/site-packages/nvidia/nccl/lib"

# # 3) NVSHMEM soname fallback (some wheels only ship libnvshmem.so)
# [ -f "$NVSHMEM_LIB_DIR/libnvshmem.so.3" ] || \
#   { [ -f "$NVSHMEM_LIB_DIR/libnvshmem.so" ] && ln -s "$NVSHMEM_LIB_DIR/libnvshmem.so" "$NVSHMEM_LIB_DIR/libnvshmem.so.3" || true; }

# # 4) Put CUDA stub first so import works on hosts without a driver
# ln -sf /usr/local/cuda/targets/x86_64-linux/lib/stubs/libcuda.so \
#       /usr/local/cuda/targets/x86_64-linux/lib/stubs/libcuda.so.1 2>/dev/null || true

# export LD_LIBRARY_PATH="/usr/local/cuda/targets/x86_64-linux/lib/stubs:$CUDNN_LIB_DIR:$NVSHMEM_LIB_DIR:$NCCL_LIB_DIR:/usr/local/cuda/lib64"

# # 5) Sanity test (optional)
# python - <<'PY'
# import ctypes, os
# print("LD_LIBRARY_PATH=", os.environ.get("LD_LIBRARY_PATH",""))
# for lib in ["libcuda.so.1","libcudnn.so.9","libcudnn_engines_precompiled.so.9","libnvshmem_host.so.3","libnvshmem.so.3","libnccl.so.2"]:
#     ctypes.CDLL(lib)
# print("All GPU redists preloaded OK")
# PY

# # 6) TensorFlow import test (on a no-GPU host you’ll see UNKNOWN ERROR(34); that’s fine)
# python -c "import tensorflow as tf; print('TF', tf.__version__); print('GPUs:', tf.config.list_physical_devices('GPU'))"


# git clone https://github.com/tensorflow/text.git
# cd text
# git checkout test_818668082

# mkdir /github

# export IS_NIGHTLY=nightly
# export TF_VERSION=grc.io/tensorflow-sigs/build-arm64:tf-latest-multi-python

# ./oss_scripts/run_build.sh

# pip install tensorflow_text_nightly-*.whl

# #### Extra packages ####
# pip install tensorflow-metadata
# pip install tensorflow-io

# # Bazel for this "old" packages
# apt update && apt install bazel-6.5.0

# pip install pyarrow apache-beam

# # tfx-bsl
# git clone https://github.com/tensorflow/tfx-bsl.git
# cd tfx-bsl
# pip install . --no-deps -v
# cd ..

# # tf 2 onnix
# git clone https://github.com/tensorflow/tensorflow-onnx.git
# cd tensorflow-onnx
# pip install . --no-deps -v
# pip install onnx
# cd ..

# # tfdv
# git clone https://github.com/tensorflow/data-validation.git
# cd data-validation
# # Modify needed numpy version
# sed -i 's/"numpy~=1.22.0"/"numpy>=1.26"/' pyproject.toml
# pip install . --no-deps -v
# pip install pyfarmhash
# pip install IPython
# pip install joblib
# pip install pandas
# cd ..

# # tf transform
# git clone https://github.com/tensorflow/transform.git
# cd transform
# pip install . --no-deps -v
# pip install tf_keras
# cd ..



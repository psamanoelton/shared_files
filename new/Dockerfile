# ------------------------------------------------------------
# TensorFlow Quantum modern build/test env (GPU-enabled)
# ------------------------------------------------------------
FROM nvidia/cuda:12.8.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

# ------------------------------------------------------------
# System dependencies
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates gnupg build-essential pkg-config \
    python3 python3-dev python3-venv python3-pip \
    zip unzip libffi-dev libssl-dev wget bzip2 dos2unix vim \
    && rm -rf /var/lib/apt/lists/*

# Bazelisk
RUN curl -L https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 \
      -o /usr/local/bin/bazel && chmod +x /usr/local/bin/bazel

# -------------------------------------------------------------------
# Miniconda + Python 3.11 env (tf311) and accept Anaconda repo TOS
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

# Create the Python 3.12 env for runtime/tests and auto-activate it on login
RUN conda create -y -n tf311 python=3.11 && \
    echo "source ${CONDA_DIR}/etc/profile.d/conda.sh && conda activate tf311" >> /root/.bashrc && \
    echo "conda activate tf311"

    # Make sure base tools are current
RUN python3 -m pip install -U pip setuptools wheel numpy

# ------------------------------------------------------------
# Core ML stack (verified compatible)
# ------------------------------------------------------------
RUN pip install \
    tensorflow==2.20.0 \
    numpy==2.3.4 \
    cirq==1.6.1 \
    protobuf==5.29.5 \
    scipy==1.16.2 \
    sympy==1.14.0 \
    h5py==3.15.1 \
    networkx==3.5

# # ------------------------------------------------------------
# # TensorFlow Quantum source
# # ------------------------------------------------------------
WORKDIR /workspace
RUN git clone https://github.com/tensorflow/quantum.git && cd quantum && git checkout v0.7.3

# # ------------------------------------------------------------
# # Patch requirements for new stack
# # ------------------------------------------------------------
# WORKDIR /workspace/quantum
# RUN sed -i 's/tensorflow>=2\.15\.0/tensorflow>=2.20.0/' setup.py && \
#     sed -i 's/numpy<2/numpy>=2.0.0/' setup.py && \
#     sed -i 's/cirq==1\.3\.[0-9]*/cirq>=1.6.1/' setup.py

# # Optional: if using requirements.txt
# # RUN sed -i 's/protobuf.*$/protobuf>=5.28.0,<6.0/' requirements.txt

# # ------------------------------------------------------------
# # Build and install TFQ
# # ------------------------------------------------------------
# RUN pip install .

# # ------------------------------------------------------------
# # Basic import test
# # ------------------------------------------------------------
# RUN python - <<'PY'
# import tensorflow as tf, cirq, tensorflow_quantum as tfq
# print("TensorFlow:", tf.__version__)
# print("NumPy:", __import__('numpy').__version__)
# print("Cirq:", cirq.__version__)
# print("TFQ:", tfq.__version__)
# PY

CMD ["/bin/bash"]


# # To build this image, run:
# #   docker build -t tfq .

# # To run this image, run:
# #   docker run -it tfq

# # To remove the image, run:
# #   docker rm -f tfq

# # To remove all:
# # docker stop $(docker ps -qa)
# # docker rm -f $(docker ps -qa)
# # docker rmi -f $(docker images -qa)
# # docker system prune -a --volumes


# Re open the image
# # docker exec -it 05017e570307 /bin/bash


bazel build -c opt --cxxopt="-O3" --cxxopt="-march=native" --cxxopt="-std=c++20" --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=1" //tensorflow/tools/pip_package:build_pip_package

docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum" f472a0196d63:/workspace/quantum

docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum\WORKSPACE" f472a0196d63:/workspace/quantum

docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum\tensorflow_quantum\BUILD" f472a0196d63:/workspace/quantum/tensorflow_quantum

sed -i 's/\r$//' configure.sh
bash configure.sh

bazel build //tensorflow_quantum/pip_package:build_pip_package
bazel-bin/tensorflow_quantum/pip_package/build_pip_package.sh /workspace/wheel_house
pip install /workspace/wheel_house/tensorflow_quantum-0.8.0.dev-py3-none-any.whl

.bazelrc
build --noenable_bzlmod
build --incompatible_use_python_toolchains=false


python, syntax, how to use python to solve problems, django, django crud, structure, key features, posgresql, dbs operations, schema design, AWS,

# pip install -c tf220-cirq161.txt -r requirements.txt

bazel build -c opt release:build_pip_package

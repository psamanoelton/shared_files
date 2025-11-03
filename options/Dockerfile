FROM ubuntu:22.04
SHELL ["/bin/bash","-lc"]
ENV DEBIAN_FRONTEND=noninteractive

# Base toolchain
RUN apt-get update && apt-get install -y \
    python3.11 python3.11-dev python3.11-venv python3-pip \
    build-essential git curl unzip zip pkg-config zlib1g-dev \
    clang lld && rm -rf /var/lib/apt/lists/*

# Bazelisk (lets .bazelversion drive Bazel 6.5.0)
RUN curl -L https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-linux-amd64 \
      -o /usr/local/bin/bazel && chmod +x /usr/local/bin/bazel

WORKDIR /workspace
RUN python3.11 -m venv .venv && . .venv/bin/activate && \
    python -m pip install --upgrade pip wheel setuptools && \
    # Pin the safe dependency set for TF 2.16:
    pip install "tensorflow==2.16.2" "numpy>=1.26.4,<2.0" "protobuf>=4.25,<5.0" && \
    pip install "cirq-core==1.3.*" "cirq-google==1.3.*"

# Copy TFQ repo into /workspace/quantum (or docker cp later)
# COPY quantum /workspace/quantum

WORKDIR /workspace
CMD ["/bin/bash"]

# docker build -t tfqn -f Dockerfilenew .
# docker run -it tfqn

# source .venv/bin/activate


# $src = "C:\Users\Pablo Samano\Desktop\Rivian\google"   # change to your path
# docker run --rm -it --name tfq --mount type=bind,source="$src",target=/workspace tfqn /bin/bash






FROM ubuntu:22.04
SHELL ["/bin/bash","-lc"]
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Base toolchain + Python 3.11 + Clang/LLD
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 python3.11-dev python3.11-venv python3.11-distutils \
    build-essential git curl unzip zip pkg-config zlib1g-dev \
    clang lld ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Bootstrap pip for Python 3.11 (ensurepip is disabled on Ubuntu)
RUN curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py && \
    python3.11 /tmp/get-pip.py && rm /tmp/get-pip.py && \
    python3.11 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Bazelisk (lets repo’s .bazelversion select Bazel)
RUN curl -L https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-linux-amd64 \
      -o /usr/local/bin/bazel && chmod +x /usr/local/bin/bazel

WORKDIR /workspace

# Python deps (system Python 3.11 — no venv)
# TF 2.16.2 + legacy Keras shim; route tf.keras -> Keras-2
ENV TF_USE_LEGACY_KERAS=1
RUN python3.11 -m pip install --no-cache-dir \
      "tensorflow==2.16.2" \
      "tf-keras==2.16.0" \
      "numpy==1.26.4" "protobuf>=4.25,<5.0" \
      "cirq-core==1.3.*" "cirq-google==1.3.*" \
      "sympy==1.14.0" "absl-py>=1.4.0"

# (Optional) copy your TFQ repo now, otherwise you can docker cp later
# COPY quantum/ /workspace/quantum/

# If you copied from Windows, normalize LF endings once inside the container:
#   sed -i 's/\r$//' /workspace/quantum/configure.sh /workspace/quantum/scripts/*.sh || true

CMD ["/bin/bash"]



# docker build -t tfq-tf216:latest .
# docker run -it tfq
# docker exec -it c6b726628065 /bin/bash

# source .venv/bin/activate

# pip install -r requirements.txt
# ./configure.sh
# bazel build -c opt --cxxopt="-O3" --cxxopt="-march=native" --cxxopt="-std=c++17" --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=1" release:build_pip_package
# bazel-bin/release/build_pip_package /tmp/tfquantum/
# python3 -m pip install /tmp/tfquantum/name_of_generated_wheel.whl

# # $src = "C:\Users\Pablo Samano\Desktop\Rivian\google"   # change to your path
# # docker run --rm -it --name tfqq --mount type=bind,source="$src",target=/workspace tfqn /bin/bash

# docker run --rm -it --name tfq -v "C:\Users\Pablo Samano\Desktop\Rivian\google":/workspace tfq-tf216:latest

docker run --rm -it --name tfqn -v "C:\Users\Pablo Samano\Desktop\Rivian\google":/workspace tfq-tf216:latest


# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum\WORKSPACE" a05debad652a:/workspace/quantum
# docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum" a05debad652a:/workspace

### END 2 END ###
# choose your env
python3.11 -m venv .venv && . .venv/bin/activate
pip install -U pip
pip install tensorflow==2.16.2 tf-keras==2.16.0 numpy==1.26.4 \
            sympy==1.14.0 protobuf>=4.25,<5 cirq-core==1.3.* cirq-google==1.3.*

# reconfigure with your venv python
./configure.sh --python="$(pwd)/.venv/bin/python"

# make sure Windows line-endings didn’t sneak in
sed -i 's/\r$//' release/build_pip_package.sh scripts/*.sh configure.sh || true
chmod +x release/build_pip_package.sh scripts/*.sh configure.sh

# clean & build
bazel clean --expunge
bazel build -c opt \
  --cxxopt="-O3" --cxxopt="-march=native" --cxxopt="-std=c++17" \
  --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=1" --linkopt="-fuse-ld=lld" \
  release:build_pip_package

# build the wheel with the same interpreter (thanks to our build_pip_package.sh patch)
bazel-bin/release/build_pip_package /tmp/tfquantum

pip install /tmp/tfquantum/*.whl

# sanity
PY
import tensorflow as tf, tensorflow_quantum as tfq, tf_keras as k2, cirq, numpy as np, sympy
print("TF:", tf.__version__)
print("TFQ:", tfq.__version__)
print("tf-keras:", k2.__version__)
print("Cirq:", cirq.__version__)
print("NumPy:", np.__version__)
print("Sympy:", sympy.__version__)
PY

###





# sed -i 's/\r$//' bazel-bin/release/build_pip_package
# bazel-bin/release/build_pip_package /tmp/tfquantum
# sed -i 's/\bpython3\b/python3.11/g' bazel-bin/release/build_pip_package
# bazel-bin/release/build_pip_package /tmp/tfquantum
# pip install /tmp/tfquantum/*.whl

cd /workspace
python - <<'PY'
import tensorflow as tf, tensorflow_quantum as tfq, cirq, numpy as np, google.protobuf as gp, sympy
print("TF:", tf.__version__)
print("TFQ:", tfq.__version__)
print("Cirq:", cirq.__version__)
print("NumPy:", np.__version__)
print("Protobuf:", gp.__version__)
print("sympy:", sympy.__version__)
print("tfq from:", tfq.__file__)
PY

# sed -i 's/\r$//' scripts/test_all.sh
# ./scripts/test_all.sh




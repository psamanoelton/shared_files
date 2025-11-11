FROM ubuntu:22.04

SHELL ["/bin/bash","-lc"]
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# --------------------------------------------------------------------
# OS deps (Bazel needs a JDK)
# --------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git curl unzip zip pkg-config zlib1g-dev ca-certificates \
    clang lld \
    openjdk-17-jdk \
 && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# --------------------------------------------------------------------
# Bazelisk
# --------------------------------------------------------------------
RUN curl -L https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-linux-amd64 \
      -o /usr/local/bin/bazel && chmod +x /usr/local/bin/bazel

# --------------------------------------------------------------------
# Miniforge (conda-forge; no Anaconda ToS prompts)
# --------------------------------------------------------------------
ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:${PATH}
RUN curl -fsSL https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -o /tmp/mf.sh && \
    bash /tmp/mf.sh -b -p ${CONDA_DIR} && rm -f /tmp/mf.sh && \
    conda config --system --set always_yes yes --set changeps1 no && \
    conda config --system --add channels conda-forge && \
    conda config --system --set channel_priority strict && \
    conda update -n base conda

# --------------------------------------------------------------------
# Create env, prep pip; only symlink if missing (usually already exists)
# --------------------------------------------------------------------
ENV PIP_ROOT_USER_ACTION=ignore
RUN conda create -n tfq python=3.11 pip && \
    ${CONDA_DIR}/envs/tfq/bin/python -m pip install --no-cache-dir --upgrade pip setuptools wheel && \
    if [ ! -x "${CONDA_DIR}/envs/tfq/bin/python3.11" ]; then \
      ln -s ${CONDA_DIR}/envs/tfq/bin/python ${CONDA_DIR}/envs/tfq/bin/python3.11; \
    fi

# Make conda available in all bash shells and auto-activate tfq
RUN echo "source /opt/conda/etc/profile.d/conda.sh" >> /etc/bash.bashrc && \
    echo "conda activate tfq" >> /etc/bash.bashrc

WORKDIR /workspace

# --------------------------------------------------------------------
# Clone + build + install TFQ (your branch) inside the tfq env
# --------------------------------------------------------------------
RUN git clone https://github.com/psamanoelton/quantum.git && \
    cd quantum && \
    git checkout feature/tf216_support && \
    source ${CONDA_DIR}/etc/profile.d/conda.sh && conda activate tfq && \
    pip install --no-cache-dir -r requirements.txt && \
    ./configure.sh --python="$(which python3.11)" && \
    bazel clean --expunge && \
    bazel build -c opt \
      --cxxopt="-O3" --cxxopt="-march=native" --cxxopt="-std=c++17" \
      --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=1" --linkopt="-fuse-ld=lld" \
      release:build_pip_package && \
    bazel-bin/release/build_pip_package /tmp/tfquantum && \
    pip install --no-cache-dir /tmp/tfquantum/*.whl

# --------------------------------------------------------------------
# Quick runtime check (fail-fast during build)
# --------------------------------------------------------------------
RUN source ${CONDA_DIR}/etc/profile.d/conda.sh && conda activate tfq && \
python - <<'PY'
import tensorflow as tf, tensorflow_quantum as tfq, tf_keras as k2, cirq, numpy as np, sympy
print("TF:", tf.__version__)
print("TFQ:", tfq.__version__)
print("tf-keras:", k2.__version__)
print("Cirq:", cirq.__version__)
print("NumPy:", np.__version__)
print("Sympy:", sympy.__version__)
PY

CMD ["/bin/bash"]

# ### END DOCKERFILE ###`



# docker build -t tfq-tf:latest .
# docker run -it tfq-tf:latest
# docker exec -it ea2ae16ac6f4 /bin/bash

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


# # docker cp "C:\Users\Pablo Samano\Desktop\Rivian\google\quantum\WORKSPACE" a05debad652a:/workspace/quantum
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

cd quantum
./scripts/test_all.sh
./scripts/ci_validate_tutorials.sh

# 2) Nuke stale external repos and analysis cache
rm -rf "$(bazel info output_base)"/external/local_config_python \
       "$(bazel info output_base)"/external/local_execution_config_python \
       "$(bazel info output_base)"/external/python \
       "$(bazel info output_base)"/external/local_config_tf 2>/dev/null || true
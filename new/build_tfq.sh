#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   bash build_tfq.sh
#
# Assumes you're in the root of the TFQ repo (tensorflow/quantum).
# This script:
#  1) Creates a clean venv (Python 3.11).
#  2) Installs a unified dependency set for TF 2.20 + NumPy 2.3.4 + Cirq 1.6.1.
#  3) Runs TFQ's configure step non-interactively.
#  4) Builds TFQ C++ ops with Bazel 7.x.
#  5) Imports TFQ and runs a micro test to verify basic functionality.

PYTHON_BIN="${PYTHON_BIN:-python3.11}"
VENV_DIR="${VENV_DIR:-.venv_tfq220}"
REQS_FILE="${REQS_FILE:-./tfq_env_requirements.txt}"

echo "[1/6] Creating virtualenv: ${VENV_DIR} (python: ${PYTHON_BIN})"
${PYTHON_BIN} -m venv "${VENV_DIR}"
source "${VENV_DIR}/bin/activate"
python -m pip install -U pip wheel setuptools

echo "[2/6] Installing dependencies from ${REQS_FILE}"
pip install -r "${REQS_FILE}"
pip check || true

echo "[3/6] Preparing non-interactive Bazel config"
# Keep the configure.sh script non-interactive by pre-setting the vars:
export TF_NEED_CUDA="${TF_NEED_CUDA:-1}"
export TF_CUDA_VERSION="${TF_CUDA_VERSION:-12}"

echo "[4/6] Running ./configure.sh (non-interactive paths via TF sysconfig)"
bash ./configure.sh <<EOF
n
y
EOF

echo "[5/6] Building TFQ targets with Bazel"
# Ensure Bazel 7 is used (bazelisk recommended). You can also set .bazelversion.
bazel --version || true
bazel clean --expunge
bazel build //tensorflow_quantum/...

echo "[6/6] Import smoke tests"
python - <<'PY'
import tensorflow as tf
import cirq, numpy as np
import tensorflow_quantum as tfq
print("TF:", tf.__version__)
print("Cirq:", cirq.__version__)
print("NumPy:", np.__version__)
# Minimal convert + layer check:
q = cirq.LineQubit(0)
c = cirq.Circuit(cirq.X(q)**0.5)
t = tfq.convert_to_tensor([c])
m = tf.keras.Sequential([tfq.layers.PQC(c, cirq.Z(q))])
print("TFQ convert + Keras PQC OK")
PY

echo "Build & basic import test completed successfully."

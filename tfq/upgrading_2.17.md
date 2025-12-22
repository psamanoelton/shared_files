# Upgrading TFQ to TensorFlow 2.17 (with Keras 2 / Legacy Mode)

This guide explains how to move this repository from **TF 2.16 → TF 2.17** while
**staying on Keras 2 semantics** via the legacy bridge. It captures the exact pins,
scripts, and checks that worked for 2.16 and how to safely adjust them for 2.17.

We deliberately **avoid macOS** for now (Linux-only CI) and keep **NumPy < 2.0**.
We also keep our **protobuf** pins from the 2.16 setup and **Bazel 6.5.0**.

---

## TL;DR (minimal required changes)

- **TensorFlow**: `tensorflow==2.17.*`
- **Keras 2 (legacy)**: `tf-keras==2.17.*` and export `TF_USE_LEGACY_KERAS=1` during build/tests
- **NumPy**: `numpy==1.26.4` (keep `<2.0` for TF 2.17)
- **Bazel**: `.bazelversion` → `6.5.0`
- **qsim**: bump to the latest compatible release (see _qsim_ section)
- **Tutorials (RL)**: **`gym==0.25.2`** (keep this exact version to avoid gymnasium API changes)
- **OS**: Linux only (skip macOS for now)
- **Protobuf**: reuse the working 2.16 pins

---

## 1) Version pins (requirements)

Update your `requirements.in` / `requirements.txt` to include (or keep) the following pins:

```txt
# Core
tensorflow==2.17.*
tf-keras==2.17.*      # legacy Keras 2 bridge
numpy==1.26.4         # keep < 2.0 for TF 2.17

# Tutorials / Jupyter stack (py311/py312 friendly)
ipython==8.26.0
ipykernel==6.29.5
jupyter-client==8.6.0
nbclient==0.9.0
seaborn==0.12.2

# RL tutorial
gym==0.25.2

# Keep your working 2.16-compatible pins here
absl-py>=1.4.0
protobuf==4.25.*
# ... (any other repo-specific pins you already validated on 2.16)
```

> **Why these pins?**
> - TF 2.17 doesn’t officially support NumPy 2.0. Keep NumPy 1.26.x.
> - We stay on Keras 2 behavior by installing `tf-keras==2.17.*` and exporting `TF_USE_LEGACY_KERAS=1`.
> - `gym==0.25.2` preserves the old `(obs, reward, done, info)` step API used by the RL notebook.

---

## 2) Bazel/toolchain & Python

- Keep `.bazelversion` at **`6.5.0`**.
- Continue to use **Bazelisk**.
- Keep the **python toolchain “literal path” fix**:
  - Our `configure.sh` writes `third_party/python_legacy/defs.bzl` with:
    ```bzl
    interpreter = "/absolute/path/to/python"
    py_runtime = native.py_runtime
    ```
  - This avoids Bazel’s `py_runtime` “function value” errors by providing a **string** interpreter path.

---

## 3) `configure.sh` (no surprises)

Continue to:
- Detect TF include/lib paths via `tensorflow.sysconfig`.
- Write `.tf_configure.bazelrc` with:
  - `PYTHON_BIN_PATH`
  - `TF_HEADER_DIR`
  - `TF_SHARED_LIBRARY_DIR`
  - `TF_SHARED_LIBRARY_NAME`
  - `TF_USE_LEGACY_KERAS=1`
  - (CPU build default is fine; GPU is optional and currently off for CI)

Example lines to keep (already present in our script):

```bash
write_tf_rc "build --repo_env=PYTHON_BIN_PATH=$PYTHON_BIN_PATH"
write_tf_rc "build --repo_env=TF_HEADER_DIR=$HDR"
write_tf_rc "build --repo_env=TF_SHARED_LIBRARY_DIR=$LIBDIR"
write_tf_rc "build --repo_env=TF_SHARED_LIBRARY_NAME=$LIBNAME"
write_tf_rc "build --repo_env=TF_USE_LEGACY_KERAS=1"

write_bazelrc "build --action_env=TF_USE_LEGACY_KERAS=1"
write_bazelrc "test  --action_env=TF_USE_LEGACY_KERAS=1"
```

> **Tip:** Always invoke `./configure.sh --python="$(which python)"` to lock to your active interpreter.

---

## 4) qsim

- Bump to the **latest qsim** that builds cleanly with TF 2.17 and your compiler.
- If qsim is vendored or pinned, update the ref and test the TFQ op builds.
- If you see warnings from qsim, keep the targeted warning suppressions you already use in `.bazelrc`.

---

## 5) Tutorials (Jupyter + RL)

### ci_validate_tutorials.sh

- Keep the same stack as 2.16, just bump TF/legacy-keras pins to 2.17.
- **Important**: Continue to install **`gym==0.25.2`** (avoid gymnasium API changes).
- Install the ipykernel **for the exact interpreter** running the script.

Example skeleton:

```bash
#!/usr/bin/env bash
set -euo pipefail

PY="${PYTHON_BIN_PATH:-python3}"
PIP="$PY -m pip"

export TF_USE_LEGACY_KERAS=1

$PIP install --no-cache-dir -U \
  "tensorflow==2.17.*" "tf-keras==2.17.*" "numpy==1.26.4" \
  ipython==8.26.0 ipykernel==6.29.5 jupyter-client==8.6.0 nbclient==0.9.0 \
  seaborn==0.12.2 gym==0.25.2 \
  git+https://github.com/tensorflow/docs

KERNEL_NAME="tfq-py"
"$PY" -m ipykernel install --user --name "$KERNEL_NAME" \
   --display-name "Python (tfq)"

export SDL_VIDEODRIVER=dummy
export PYGAME_HIDE_SUPPORT_PROMPT=1

cd ..
"$PY" quantum/scripts/test_tutorials.py
```

### `scripts/test_tutorials.py`

- Keep the **CI fast-path** in the RL tutorial execution (few episodes & capped steps).
- If you ever switch to gymnasium, retain the small shim that adapts the step/return signature—but with `gym==0.25.2` the existing tutorial runs as-is.
- Ensure each notebook executes with `resources={"metadata":{"path": dirname(nb_path)}}` so relative paths work.

---

## 6) CI (Linux-only)

Recommended GitHub Actions flow:

1. **Set up Python** (3.11 and/or 3.12)
2. **Install build deps** (pip, wheel, etc.)
3. **Run `./configure.sh`** with the step’s Python
4. **Bazel tests** (a small subset is fine for smoke)
5. **Build wheel**
6. **Install wheel** into the runner’s Python
7. **Run `scripts/ci_validate_tutorials.sh`**
8. **Lint**:
   ```bash
   pylint -v release/setup.py tensorflow_quantum/__init__.py scripts/test_tutorials.py
   ```

We **skip macOS** for now. Consider adding it back for 2.19+.

---

## 7) Local validation (container)

```bash
# 1) Configure
./configure.sh --python="$(which python)"

# 2) Clean
bazel clean --expunge

# 3) Quick native tests
bazel test -c opt --test_output=errors \
  //tensorflow_quantum/core/serialize:op_serializer_test \
  //tensorflow_quantum/core/serialize:op_deserializer_test \
  //tensorflow_quantum/core/ops/math_ops:inner_product_op_test

# 4) Build wheel
bazel build -c opt //release:build_pip_package
bazel-bin/release/build_pip_package /tmp/tfquantum

# 5) Install wheel
python -m pip install /tmp/tfquantum/tensorflow_quantum-*.whl --force-reinstall

# 6) Tutorials
scripts/ci_validate_tutorials.sh

# 7) Lint
pylint -v release/setup.py tensorflow_quantum/__init__.py scripts/test_tutorials.py
```

---

## 8) Common pitfalls (and fixes)

- **NumPy 2.0 pulled transitively** → Pin `numpy==1.26.4`.
- **Keras mismatches** (e.g., importing Keras 3 inadvertently) → Ensure both
  `tf-keras==2.17.*` is installed and `TF_USE_LEGACY_KERAS=1` is exported in build/test jobs.
- **RL tutorial timeout or API errors** → Keep `gym==0.25.2`.
- **Bazel Python toolchain error** (`interpreter_path` function vs string) → Keep `third_party/python_legacy/defs.bzl` with a **literal** interpreter path string (written by `configure.sh`).
- **Mac wheels** → Not supported for now; skip macOS CI.
- **Jupyter kernel mismatch** → Always install the ipykernel for the same Python that runs tests.
- **Pylint warnings** from `.pylintrc` → Keep the trimmed rules you already applied for this repo.

---

## 9) Release checklist

- [ ] Update `requirements.*` with TF 2.17 pins (and keep NumPy 1.26.4).
- [ ] Verify `.bazelversion=6.5.0`.
- [ ] Run full local validation (build → wheel → tutorials → lint).
- [ ] Verify `scripts/test_tutorials.py` prints green for all notebooks.
- [ ] Push PR; ensure CI passes on Linux runners.
- [ ] Tag and publish the wheel if applicable.

---

## 10) Planning ahead (TF 2.18+)

- For **TF 2.18**, we can explore **NumPy 2.0** support and revisit gym/gymnasium choices.
- Consider re-enabling **macOS** in 2.19+ once wheel availability & pins are confirmed.
- If you later enable GPU builds, re-check CUDA/cuDNN plugin compatibility on TF 2.17+.

---

**That’s it.** This mirrors the working 2.16 flow, limits risk, and keeps the RL notebook stable for CI.
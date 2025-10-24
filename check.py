
import platform
import sys

print("Python version:", sys.version)
print("Architecture:", platform.architecture()[0])
print("Architecture:", platform.machine())

try:
    import tensorflow_io as tf_io
    print("TensorFlow I/O version:", tf_io.__version__)
except ImportError:
    print("TensorFlow I/O is not installed.")

import tensorflow as tf

print("TensorFlow version:", tf.__version__)

try:
    import tensorflow_metadata as tf_metadata
    print("Tensorflow Metadata installed")
except ImportError:
    print("Tensorflow Metadata not installed")

try:
    import tensorflow_data_validation as tfdv
    print("Tensorflow Data Validation version:", tfdv.__version__)
except ImportError:
    print("Tensorflow Data Validation not installed")

try:
    import tensorflow_transform as tft
    print("Tensorflow Transform version:", tft.__version__)
except ImportError:
    print("Tensorflow Transform not installed")

try:
    import tfx_bsl
    print("TFX BSL version:", tfx_bsl.__version__)
except ImportError:
    print("TFX BSL not installed")

try:
    import tf2onnx
    print("tf2onnx version:", tf2onnx.__version__)
except ImportError:
    print("tf2onnx not installed")

try:
    import tensorflow_text as tf_text
    print("TensorFlow Text version:", tf_text.__version__)
except Exception as e:
    print("TensorFlow Text not installed or failed to import:", str(e))



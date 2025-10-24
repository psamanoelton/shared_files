import pkg_resources


def get_requires(pkg):
    dist = pkg_resources.get_distribution(pkg)
    return {r.project_name.lower(): str(r) for r in dist.requires()}

tf_reqs = get_requires("tensorflow")
cirq_reqs = get_requires("cirq")
numpy_reqs = get_requires("numpy")

print("TensorFlow:", tf_reqs)
print("Cirq:", cirq_reqs)
print("NumPy:", numpy_reqs)

# Compare overlaps
common = set(tf_reqs) & set(cirq_reqs)
for dep in common:
    print(f"{dep}: TF={tf_reqs[dep]} | Cirq={cirq_reqs[dep]}")

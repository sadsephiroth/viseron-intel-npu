FROM roflcoopter/viseron:latest

USER root

# Install Intel Level-Zero compute runtime and OpenVINO runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    intel-level-zero-gpu \
    level-zero \
    && rm -rf /var/lib/apt/lists/*

# Install OpenVINO and Ultralytics without caching wheels
RUN pip install --no-cache-dir \
    "openvino>=2024.4.0" \
    "ultralytics>=8.3.0"

# Patch 1: filelock fork-safety audit hook bypass (Python 3.12 multiprocessing)
RUN python3 -c " \
path = '/usr/local/lib/python3.12/dist-packages/filelock/_api.py'; \
with open(path, 'r') as f: code = f.read(); \
target = 'def _audit_fork_safety(self, event: str, args: tuple[Any, ...]) -> None:'; \
assert target in code, 'filelock target signature not found'; \
code = code.replace(target, target + '\n        return'); \
with open(path, 'w') as f: f.write(code); \
"

# Patch 2: Prioritize NPU execution in Ultralytics OpenVINO backend
RUN python3 -c " \
path = '/usr/local/lib/python3.12/dist-packages/ultralytics/nn/backends/openvino.py'; \
with open(path, 'r') as f: code = f.read(); \
old = 'fallback_device = \"CPU\" if core.available_devices == [\"CPU\"] else \"AUTO\"'; \
new = 'fallback_device = \"NPU\" if \"NPU\" in core.available_devices else (\"CPU\" if core.available_devices == [\"CPU\"] else \"AUTO\")'; \
assert old in code, 'ultralytics target fallback string not found'; \
code = code.replace(old, new); \
with open(path, 'w') as f: f.write(code); \
"

# Configure /tmp/Ultralytics permissions and disable telemetry checks
RUN mkdir -p /tmp/Ultralytics && \
    python3 -c " \
import json; \
with open('/tmp/Ultralytics/settings.json', 'w') as f: \
    json.dump({'sync': False, 'check': False}, f, indent=2); \
" && \
    chown -R abc:abc /tmp/Ultralytics

USER abc

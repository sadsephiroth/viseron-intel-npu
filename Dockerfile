FROM roflcoopter/viseron:latest

# Install OpenVINO and Ultralytics
RUN pip install --no-cache-dir \
    "openvino>=2024.4.0" \
    "ultralytics>=8.3.0"

# Patch 1: Neutralize filelock fork-safety audit hook at module scope
RUN echo '_audit_fork_safety = lambda *args, **kwargs: None' >> \
    /usr/local/lib/python3.12/dist-packages/filelock/_api.py

# Patch 2: Prioritize NPU execution in Ultralytics OpenVINO backend
RUN sed -i 's/fallback_device = "CPU" if core.available_devices == \["CPU"\] else "AUTO"/fallback_device = "NPU" if "NPU" in core.available_devices else ("CPU" if core.available_devices == ["CPU"] else "AUTO")/' \
    /usr/local/lib/python3.12/dist-packages/ultralytics/nn/backends/openvino.py

# Configure /tmp/Ultralytics permissions and disable telemetry checks
RUN mkdir -p /tmp/Ultralytics && \
    printf '{\n  "sync": false,\n  "check": false\n}\n' > /tmp/Ultralytics/settings.json && \
    chmod -R 777 /tmp/Ultralytics

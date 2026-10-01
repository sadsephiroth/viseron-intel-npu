FROM roflcoopter/viseron:latest

# Step 1: Remove dead repos & install driver dependencies (libze1, libtbb12)
RUN rm -f /etc/apt/sources.list.d/*coral* /etc/apt/sources.list.d/*2350* && \
    apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    libze1 \
    libtbb12 \
    intel-opencl-icd \
    intel-level-zero-gpu \
    && rm -rf /var/lib/apt/lists/*

# Step 2: Download and install Intel Linux NPU Driver release for Ubuntu 24.04
ARG NPU_VER=v1.38.0
ARG NPU_BUILD=v1.38.0.20260910-34487311128
RUN mkdir -p /tmp/npu && cd /tmp/npu && \
    curl -fSsLO https://github.com/intel/linux-npu-driver/releases/download/${NPU_VER}/linux-npu-driver-${NPU_BUILD}-ubuntu2404.tar.gz && \
    tar -xvf linux-npu-driver-${NPU_BUILD}-ubuntu2404.tar.gz && \
    dpkg -i *.deb && \
    rm -rf /tmp/npu && \
    ldconfig

# Step 3: Install OpenVINO and Ultralytics
RUN pip install --no-cache-dir \
    "openvino>=2024.4.0" \
    "ultralytics>=8.3.0"

# Step 4: Patch filelock fork-safety audit hook directly in method body using regex
RUN python3 -c "import re; p='/usr/local/lib/python3.12/dist-packages/filelock/_api.py'; c=open(p).read(); open(p,'w').write(re.sub(r'def _audit_fork_safety\([^)]*\)[^:]*:', 'def _audit_fork_safety(*args, **kwargs):\n    return None', c))"

# Step 5: Prioritize NPU execution in Ultralytics OpenVINO backend
RUN sed -i 's/fallback_device = "CPU" if core.available_devices == \["CPU"\] else "AUTO"/fallback_device = "NPU" if "NPU" in core.available_devices else ("CPU" if core.available_devices == ["CPU"] else "AUTO")/' \
    /usr/local/lib/python3.12/dist-packages/ultralytics/nn/backends/openvino.py

# Step 6: Configure /tmp/Ultralytics permissions and disable telemetry checks
RUN mkdir -p /tmp/Ultralytics && \
    printf '{\n  "sync": false,\n  "check": false\n}\n' > /tmp/Ultralytics/settings.json && \
    chmod -R 777 /tmp/Ultralytics

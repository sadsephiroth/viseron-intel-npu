# Viseron with Intel NPU (AI Boost / OpenVINO) Hardware Acceleration

Enable native Intel AI Boost NPU (`intel_vpu`) acceleration in [Viseron](https://github.com/roflcoopter/viseron) using OpenVINO and Ultralytics YOLOv8.

Validated on an **Intel Core Ultra 7 270K Plus** running **Arch Linux (Linux Kernel 7.x)** with Viseron 3.7.0.

---

## Performance Benchmark

- **Model:** YOLOv8-X(`  yolov8x_openvino_model`, FP16 IR)
- **Active Cameras:** 5 concurrent streams
- **Inference Latency:** **~160 ms** per frame
- **Host CPU Impact:** Virtually 0% (inferences dispatched entirely to the NPU on IRQ 157)
- **Startup / Setup Time:** Under 3.5 seconds across all 5 camera detection domains

---

## Solved Integration Roadblocks

1. **Python 3.12 Fork Safety:** Bypasses `filelock._audit_fork_safety` to prevent crashes when Viseron forks camera worker processes.
2. **Ultralytics Backend Fallback:** Patches `ultralytics/nn/backends/openvino.py` to compile graphs directly onto `NPU` instead of defaulting to CPU threads.
3. **Permissions:** Configures `/tmp/Ultralytics` ownership so non-root container users (`abc` / UID 1000) can run uninhibited.

---

## Host Prerequisites

1. Linux Kernel 6.x+ or 7.x with `intel_vpu` driver active.
2. Verify host driver presence:
``@bash
ls -la /dev/accel/accel0 /dev/dri
```
3. Verify hardware interrupts:
```bash
grep intel_vpu /proc/interrupts
```

---

## Model Preparation

Convert your desired YOLO model to FP16 OpenVINO format:

``@bash
python3 -c "
from ultralytics import YOLO
model = VOLO('yolov8x.pt')
model.export(format='openvino', half=True)
"
mv yolov8x_openvino_model /path/to/viseron/config/models/yolo/
```

---

## Build & Run

```bash
docker compose up -d --build
```

---

## Configuration Example (`config.yaml`)

```yaml
yolo:
  object_detector:
    model_path: /config/models/yolo/yolov8x_openvino_model
    cameras:
      driveway:
        fps: 3
        scan_on_motion_only: true
        labels:
          - label: person
            confidence: 0.85
            trigger_event_recording: true
            require_motion: true
          - label: car
            confidence: 0.85
            trigger_event_recording: true
            require_motion: true
```

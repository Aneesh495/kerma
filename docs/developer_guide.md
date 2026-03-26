# Kerma Developer and Build Guide

## Prerequisites

- C++20 compatible compiler: Clang (>= 15.0), GCC (>= 12.0), or MSVC (>= 19.30)
- CMake (>= 3.20)
- Python (>= 3.10) with NumPy
- glslangValidator (from Vulkan SDK or standalone)

## Building the C++ Fastpath

```bash
mkdir build
cd build
cmake ..
cmake --build . -j4
```

This compiles:
1. `libkerma_core.a`: C++ static core dosimetry library.
2. `kerma_cli`: Command-line executable for phantom generation, dose computation, and QA reporting.
3. `kerma_tests`: Comprehensive unit test executable.

## Running Tests

### 1. C++ Verification Test Suite
```bash
./build/kerma_tests
```

### 2. Python Verification Test Suite
```bash
PYTHONPATH=python python3 -m unittest discover -s python/tests -v
```

### 3. GLSL Shader Compilation to SPIR-V
```bash
python3 tools/validate_shaders.py
```

### 4. Typography Auditor (Zero Em Dash Invariant)
```bash
python3 tools/check_typography.py
```

Or execute everything via the Makefile:
```bash
make all
make test
```

## Running the CLI Fastpath

```bash
./build/kerma_cli --phantom thorax --gantry 0 --mu 250
```

Sample output:
```
=================================================================
KERMA: GPU-Accelerated Radiation Oncology Dosimetry Engine
Clinical Treatment Planning and Verification CLI Fastpath
=================================================================
[1/4] Synthesizing 3D Anatomical CT Phantom: thorax (64x64x64)...
      Completed in 1.5 ms.
[2/4] Configuring Linac Treatment Beam (Gantry = 0 deg, MU = 250)...
[3/4] Executing 3D Analytical Pencil Beam Dose Engine...
      Dose computed in 1.6 ms.
      Peak Absorbed Dose: 2.798 Gy
[4/4] Performing Clinical DVH Analysis and TG-218 QA Verification...
-----------------------------------------------------------------
  TARGET DOSIMETRY REPORT [PTV]:
    Volume (cc):           11.312
    Mean Dose (Gy):        1.238
    D98 (Near-min Gy):     0.005
    D95 (Coverage Gy):     0.011
    D50 (Median Gy):       1.797
    D2  (Near-max Gy):     2.018
    Homogeneity Index:     1.120
-----------------------------------------------------------------
  TG-218 GAMMA QA VERIFICATION (3% / 3 mm):
    Evaluated Voxels:      37712
    Passing Voxels:        37712
    Gamma Passing Rate:    100.000 %
    Mean Gamma:            0.000
=================================================================
```

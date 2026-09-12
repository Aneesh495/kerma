# Verification, Validation, and Regression Report

This document summarizes the multi-tier verification framework used to ensure numerical accuracy, cross-language parity, SPIR-V shader compliance, and clinical safety constraints across Project Kerma.

## 1. Multi-Tier Verification Architecture

```
+-------------------------------------------------------------------+
|                     KERMA VERIFICATION GATES                      |
+-------------------------------------------------------------------+
|  [Gate 1] SPIR-V Compilation (tools/validate_shaders.py)          |
|           - Validates all .comp, .vert, and .frag shaders         |
|           - Enforces GLSL 450/460 std140/std430 buffer layouts    |
|                                                                   |
|  [Gate 2] C++20 Fastpath Unit Suite (cmake + ./build/kerma_tests) |
|           - Phantom synthesis & HU-to-density calibration         |
|           - IEC 61217 coordinate frames & MLC aperture clipping   |
|           - PBC & Bortfeld Bragg peak analytical dosimetry        |
|           - AAPM TG-218 3D Gamma Index (3%/2mm pass/fail checks)  |
|           - AAPM TG-43 brachytherapy line-source dose rates       |
|           - Clinical DVH metrics & homogeneity indices            |
|           - NIST stoichiometric materials & stopping powers       |
|                                                                   |
|  [Gate 3] Python Digital Twin Suite (unittest discover)           |
|           - Cross-language parity with C++20 reference grids      |
|           - Dataset schema, spectra normalization, kernel checks  |
|           - Radiobiology BED, EQD2, gEUD, LKB-NTCP, TCP models    |
|                                                                   |
|  [Gate 4] Static Typography & Style Audit                         |
|           - tools/check_typography.py enforces clean ASCII prose  |
+-------------------------------------------------------------------+
```

## 2. Documented Bug Reproduction & Regression History

Every defect discovered during development is captured with a failing test case before fixing the implementation, preserving the test permanently in the suite:

1. **Multi-Entry Test Runner Linking Error**:
   - *Symptom*: Consolidating C++ test files into a single `kerma_tests` binary triggered duplicate `main` linker failures.
   - *Resolution*: Refactored suite functions into isolated entry points orchestrated by `cpp/tests/test_runner.cpp`.
2. **SPIR-V Image Atomic Float Extension Requirement**:
   - *Symptom*: `shaders/monte_carlo/mc_klein_nishina_scatter.comp` failed SPIR-V compilation due to unrequested `GL_EXT_shader_atomic_float` on `imageAtomicAdd`.
   - *Resolution*: Standardized voxel accumulation to portable `imageLoad` / `imageStore` operations matching `mc_photon_transport.comp`.
3. **NIST Photoelectric Cross-Section Scaling & Electron Density**:
   - *Symptom*: `test_materials.cpp` failed water mass attenuation validation at 1.25 MeV (`mu/rho` exceeded NIST XCOM reference bounds of 0.055 to 0.075 cm2/g) due to an elevated photoelectric coefficient and approximate `Z/A = 0.5` factor.
   - *Resolution*: Corrected water electron density factor to exact $N_A \cdot (10/18.01528) = 3.3428 \times 10^{23}$ electrons/g and calibrated photoelectric scaling to $1.5 \times 10^{-9}\text{ cm}^2/\text{g}$ in both `cpp/src/materials_db.cpp` and `shaders/include/nist_materials_database.glsl`.
4. **Bremsstrahlung Spectra Integral Fluence Normalization**:
   - *Symptom*: `test_datasets.py` detected unnormalized weights summing to 1.1893 in `linac_6mv_spectrum.dat` and 0.8108 in `linac_15mv_spectrum.dat`.
   - *Resolution*: Normalized all four energy spectra probability distributions in `data/spectra/` to unit sum (`1.000000`).
5. **Python CLI Help String Format Escape (Python 3.14 Compatibility)**:
   - *Symptom*: Invoking `python3 -m kerma.cli` raised `ValueError: unsupported format character ')'` inside `argparse` due to an unescaped `(%)` in `--gamma-dd` help text.
   - *Resolution*: Added regression tests in `python/tests/test_cli.py` verifying `--help` and full CLI execution, then escaped `(%)` as `(%%)` in `python/kerma/cli.py`.

## 3. Running the Complete Verification Pipeline

To execute all validation gates locally:

```bash
make all
make test
```

# Kerma

Kerma is a GPU-accelerated radiation therapy simulation and dose computation suite written in GLSL compute and fragment shaders, supported by a C++20 fastpath runtime and Python validation tools.

## Architecture and Core Solvers

The engine implements multiple clinical radiation transport and verification algorithms:

1. **Stoichiometric CT Calibration (`shaders/ct/`)**
   - Hounsfield Unit mapping to mass density, relative electron density, and effective atomic numbers.
   - Dual-energy CT material decomposition and 3D external surface contour extraction.

2. **Linac Delivery Systems (`shaders/beam/`)**
   - Kramers-Schiff polyenergetic bremsstrahlung photon spectrum generation.
   - Secondary asymmetric jaw collimation with transmission penumbra.
   - Dynamic multileaf collimation (MLC) with rounded leaf-end geometry and tongue-and-groove stepped leakage.
   - Finite focal spot geometric source penumbra convolution.

3. **TERMA and Primary Transport (`shaders/terma/`)**
   - 3D numerical raycasting of radiological water-equivalent pathlengths.
   - Inverse-square law distance falloff and off-axis beam divergence correction.
   - 3D Total Energy Released per unit MAss (TERMA) volume synthesis.

4. **Radiation Transport Solvers (`shaders/cccs/`, `shaders/pbc/`, `shaders/lbte/`)**
   - Collapsed Cone Convolution Superposition (CCCS) across 128 discrete spherical solid-angle cones.
   - 3D Analytical Pencil Beam Convolution (PBC) with modified Batho and equivalent TAR heterogeneity scaling.
   - Discrete Ordinates (S_N) Linear Boltzmann Transport Equation (LBTE) spatial characteristics sweeper with positive flux fixup.

5. **Advanced Modalities (`shaders/proton/`, `shaders/brachy/`)**
   - Proton Pencil Beam Scanning (PBS) featuring Bortfeld analytical Bragg peak curves, Bohr energy straggling, nuclear halo interactions, and Fermi-Eyges multiple Coulomb scattering.
   - High-Dose-Rate (HDR) interstitial brachytherapy using the AAPM TG-43 point/line-source formalism and AAPM TG-186 heterogeneity attenuation.

6. **Monte Carlo Transport and Optimization (`shaders/monte_carlo/`, `shaders/opt/`, `shaders/adaptive/`)**
   - Woodcock delta-tracking photon transport, relativistic Klein-Nishina Compton scatter, photoelectric/Auger relaxation, Bethe-Heitler pair production, and Class II condensed-history electron stepping.
   - Inverse Fluence Map Optimization (FMO) via projected gradient descent and L-BFGS quasi-Newton solvers, plus VMAT dynamic arc interpolation.
   - Online Adaptive Radiotherapy (ART) featuring CBCT scatter correction, synthetic CT fusion, and real-time respiratory gating.

7. **4D Deformable Motion (`shaders/deform/`)**
   - 3D cubic B-spline deformation vector field (DVF) interpolation.
   - Local Jacobian determinant calculation for mass-preserving fractionated dose accumulation.

8. **Quality Assurance and Dosimetric Analysis (`shaders/qa/`, `shaders/dvh/`, `shaders/biology/`)**
   - Low's 3D Gamma Index evaluation with AAPM TG-218 criteria (3% / 3 mm and 2% / 2 mm), 1D TG-45/142 beam profile QA, and multichannel radiochromic film dosimetry.
   - Parallel reduction differential/cumulative DVH and Niemierko generalized EUD (gEUD).
   - Radiobiological modeling: BED, EQD2, Lyman-Kutcher-Burman NTCP, Zaider-Minerbo TCP, and Schneider secondary cancer risk (OED/LAR).

9. **Visualization Shaders (`shaders/render/`)**
   - Multi-Planar Reconstruction (MPR) cutting planes with DICOM window/level adjustment and anti-aliased isodose contours.
   - Beam's Eye View (BEV) DRR raycasting with MLC aperture silhouettes and anatomical ROI hatching overlays.
   - 3D Direct Volume Rendering (DVR) raymarching and 2x2 synchronized clinical workstation HUD composition.

10. **Clinical Protocol Interlocks (`rhai/protocols/`)**
    - Declarative RTOG-0617 lung SBRT, RTOG-1016 head-and-neck SIB, RTOG-0631 spine SRS, prostate VMAT dual-arc, and Linac interlock specifications.

## Documentation

- [System Architecture](docs/architecture.md)
- [Physics and Mathematical Models](docs/physics_models.md)
- [Dosimetry Commissioning Benchmarks](docs/dosimetry_benchmarks.md)
- [Verification and Regression Report](docs/verification_report.md)
- [Developer Guide](docs/developer_guide.md)
- [Clinical Standards Compliance](docs/standards.md)

## Build and Execution

### Build C++ Core and Run Tests
```bash
make all
make test
```

### Validate GLSL Shaders to SPIR-V
```bash
python3 tools/validate_shaders.py
```

### Run C++ Dosimetry CLI
```bash
./build/kerma_cli --phantom thorax --gantry 0 --mu 250
```

### Run Python Digital Twin
```bash
PYTHONPATH=python python3 -m kerma.cli --phantom thorax --gantry 0 --mu 250
```

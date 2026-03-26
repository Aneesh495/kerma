# Kerma System Architecture and Pipeline Specification

Kerma is a GPU-accelerated radiation oncology treatment planning and dose calculation engine. It combines high-throughput GLSL compute shaders with a C++20 fastpath runtime and Python simulation harnesses to solve coupled radiation transport, multileaf collimator modulation, and 4D deformable anatomical dose accumulation.

```
       +--------------------------------------------------------------+
       |             Raw DICOM CT Acquisition (HU Volume)             |
       +--------------------------------------------------------------+
                                      |
                                      v
       +--------------------------------------------------------------+
       |   Stage 1: Stoichiometric Material & Density Calibration     |
       |     - Piecewise bilinear mapping: HU -> Mass Density (rho)   |
       |     - Electron density (rho_e) and Effective Z (Z_eff)       |
       |     - 3D Patient external boundary contour extraction        |
       +--------------------------------------------------------------+
                                      |
                                      v
       +--------------------------------------------------------------+
       |   Stage 2: Medical Linac Beam Delivery Modeling              |
       |     - Kramers-Schiff polyenergetic bremsstrahlung spectrum   |
       |     - Secondary asymmetric jaw collimation (X1, X2, Y1, Y2)  |
       |     - Dynamic multileaf collimation (MLC) with tongue/groove |
       |     - Finite focal spot geometric penumbra convolution       |
       +--------------------------------------------------------------+
                                      |
                                      v
       +--------------------------------------------------------------+
       |   Stage 3: 3D Radiological Pathlength & TERMA Raymarching    |
       |     - Effective depth d_eff(r) = int rho_e(s) ds             |
       |     - Inverse-square geometric divergence (SAD / r)^2        |
       |     - 3D Primary TERMA volume generation: T(r) = (mu/rho)*Psi|
       +--------------------------------------------------------------+
                                      |
                                      v
       +--------------------------------------------------------------+
       |   Stage 4: 3D Radiation Transport & Superposition Solvers    |
       |     - Collapsed Cone Convolution Superposition (CCCS)        |
       |     - Discrete Ordinates (S_N) Linear Boltzmann Transport    |
       |     - 3D Analytical Pencil Beam Convolution (PBC)            |
       |     - Proton Pencil Beam Scanning (Bortfeld Bragg peak)      |
       |     - AAPM TG-43 High-Dose-Rate Brachytherapy Point Sources  |
       +--------------------------------------------------------------+
                                      |
                                      v
       +--------------------------------------------------------------+
       |   Stage 5: 4D Deformable Motion & Dose Accumulation          |
       |     - 3D Cubic B-spline Deformation Vector Fields (DVF)      |
       |     - Local Jacobian determinant det(J) mass preservation    |
       |     - Multi-phase respiratory cycle dose integration         |
       +--------------------------------------------------------------+
                                      |
                                      v
       +--------------------------------------------------------------+
       |   Stage 6: Clinical Quality Assurance & Verification         |
       |     - Low's 3D Gamma Index evaluation (3% / 3 mm, 2% / 2 mm) |
       |     - Parallel reduction Differential & Cumulative DVH       |
       |     - Radiobiological modeling: BED, EQD2, LKB-NTCP, TCP     |
       |     - Interactive MPR and 3D direct volume raymarching       |
       +--------------------------------------------------------------+
```

## Coordinate System Conventions

All geometric transformations in Kerma strictly adhere to the IEC 61217 international standard for radiotherapy equipment:

1. **Fixed Room Coordinate System (X_f, Y_f, Z_f)**:
   - Origin located at the Linac isocenter.
   - +Z_f points vertically upwards towards the ceiling.
   - +Y_f points horizontally from the isocenter towards the Linac gantry stand.
   - +X_f points horizontally to the right when facing the gantry stand.

2. **Gantry Coordinate System (X_g, Y_g, Z_g)**:
   - Rotates around the horizontal Y_f axis by gantry angle theta_g.
   - At theta_g = 0 degrees, the radiation source is located at (0, 0, -SAD).
   - Radiation propagates along +Z_g towards the isocenter at (0, 0, 0).

3. **Collimator Coordinate System (X_c, Y_c, Z_c)**:
   - Rotates around the central beam axis Z_g by collimator angle theta_c.
   - Defines the leaf travel axis of the multileaf collimator (MLC Bank A along -X_c, Bank B along +X_c).

4. **Patient / DICOM LPS Coordinate System**:
   - +X points Left.
   - +Y points Posterior.
   - +Z points Superior.

## Compute Shader Memory Organization

Kerma utilizes Vulkan / OpenGL GLSL compute shaders with standardized layout bindings:

- **Binding 0-3**: Readonly / Read-Write 3D textures (`image3D` or `sampler3D`) for CT Hounsfield volumes, mass density grids, radiological depth fields, and absorbed dose matrices.
- **Binding 4-7**: Shader Storage Buffer Objects (SSBOs) with `std430` layout for dynamic beamlet weights, particle arrays, leaf trajectory control points, and 1000-bin histogram reductions.
- **Binding 8-11**: Uniform Buffer Objects (UBOs) with `std140` layout for machine geometry constants, matrix transformations, and physical dosimetry parameters.

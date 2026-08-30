# Dosimetry Commissioning Benchmarks and Performance

This document details the dosimetric benchmarking methodology, reference commissioning comparisons, and computational scaling characteristics of the Kerma radiation oncology simulation engine.

## 1. Photon Beam Commissioning Benchmarks (BJR Suppl. 25 / AAPM TG-106)

Kerma supports 6 MV, 10 MV, 15 MV flattened beams and 6 MV Flattening Filter Free (FFF) high-dose-rate beams. All Bremsstrahlung spectra in `data/spectra/` are normalized to unit integral fluence and coupled with point spread energy deposition kernels in `data/kernels/`.

### 1.1 Water Phantom Depth Dose Verification

Reference Geometry:
- Source-to-Surface Distance (SSD): 100.0 cm
- Field Size at Isocenter: 10.0 x 10.0 cm2
- Grid Resolution: 2.5 x 2.5 x 2.5 mm3 across a 30 x 30 x 30 cm3 water volume

| Nominal Beam Energy | Depth of Max Dose (d_max) | PDD at 10 cm (%) | Beam Quality Index (TPR20/10) | Surface Dose Ratio (%) |
|---|---|---|---|---|
| 6 MV Flattened | 15.0 mm | 66.8% | 0.672 | 28.0% |
| 6 MV FFF | 14.0 mm | 63.4% | 0.642 | 34.0% |
| 10 MV Flattened | 24.0 mm | 73.2% | 0.741 | 21.0% |
| 15 MV Flattened | 30.0 mm | 76.8% | 0.764 | 17.5% |

## 2. Heterogeneity Interface Modeling

Dose transport across low-density lung parenchyma (rho_e = 0.258) and high-density cortical bone (rho_e = 1.795) presents secondary electron disequilibrium. Kerma validates algorithm behavior across three complexity tiers:

1. **Pencil Beam Convolution (PBC) with Batho Power-Law**: Fast initial beamlet initialization; accurately tracks primary attenuation, overestimates dose inside small lung cavities near interfaces.
2. **Collapsed Cone Convolution Superposition (CCCS)**: Density-scaled point spread raycasting along Lebedev/icosahedral solid-angle cones (`shaders/cccs/cone_superposition.comp`), capturing lateral electronic disequilibrium and re-buildup behind lung/tissue boundaries.
3. **Linear Boltzmann Transport ($S_N$) & Woodcock Monte Carlo**: Explicit multi-group angular fluence sweeps (`shaders/lbte/discrete_ordinates_sweep.comp`) and delta-tracking photon/electron cascades (`shaders/monte_carlo/`), capturing Z-dependent photoelectric enhancement inside bone and metallic implants (Ti6Al4V, 316L Stainless Steel).

## 3. Proton Pencil Beam Scanning & Brachytherapy Benchmarks

### 3.1 Proton Bortfeld Bragg Peak & Nuclear Halo
- Bragg peak depth prediction follows range-energy scaling $R_0 = \alpha E_0^p$ with $\alpha = 0.0022\text{ cm}\cdot\text{MeV}^{-1.77}$ and $p = 1.77$.
- Bohr statistical range straggling variance and nozzle momentum spread are convolved via `shaders/proton/energy_straggling.comp`.
- Non-elastic nuclear attenuation (~1.2% primary loss per cm) and secondary lateral halo dose plus $LET_d$ are evaluated in `shaders/proton/nuclear_interactions.comp`.

### 3.2 AAPM TG-43 / TG-186 Brachytherapy
- Reference HDR Ir-192 (microSelectron-v2) line-source geometry $G_L(r, \theta)$ matches TG-43 consensus within 0.5% at transverse reference point $(1.0\text{ cm}, 90^\circ)$ for $S_k = 40700\text{ U}$, $\Lambda = 1.109\text{ cGy}\cdot\text{h}^{-1}\cdot\text{U}^{-1}$.
- Heterogeneity perturbation behind high-Z tungsten rectal shields is modeled via radiological pathlength raycasting in `shaders/brachy/tg43_heterogeneity_grid.comp`.

## 4. Benchmark Harness Execution

Run the local CPU analytical and Gamma scaling benchmarks via:

```bash
python3 benchmarks/bench_shader_pipeline.py
python3 benchmarks/bench_analytical_cpu.py
python3 benchmarks/bench_gamma_scaling.py
```

# Physical and Mathematical Formulations in Kerma

This document details the analytical and numerical transport physics implemented across Kerma's GLSL compute pipeline.

## 1. Stoichiometric CT Calibration

Clinical CT scanners measure the linear X-ray attenuation coefficient mu at diagnostic energies (typically 80 to 140 kVp). Radiation therapy calculation requires mass density rho and electron density relative to water rho_e at megavoltage energies (6 to 15 MV).

Kerma implements the piecewise bilinear stoichiometric calibration curve established by Schneider, Bortfeld, and Schlegel (Phys. Med. Biol. 2000):

For Hounsfield Unit HU:
- HU in [-1000, -700]: Air to inflated lung
- HU in [-700, -120]: Lung to adipose tissue
- HU in [-120, 0]: Adipose to water
- HU in [0, +40]: Water to muscle / soft tissue
- HU in [+40, +300]: Muscle to trabecular bone
- HU in [+300, +1500]: Trabecular to dense cortical bone
- HU > +1500: Dense cortical bone to titanium prosthetic implants

## 2. TERMA Calculation

Total Energy Released per unit MAss (TERMA) represents the primary radiant energy imparted to matter per unit mass at position r:

    T_E(r) = (mu / rho)(E, r) * Psi_E(r)

where primary energy fluence Psi_E(r) accounts for inverse-square distance divergence, source focal spot penumbra, and broad-beam attenuation:

    Psi_E(r) = Psi_0(u, v) * (SAD / |r - s|)^2 * exp( -int_{s_skin}^r mu(s') ds' )

The line integral through the patient density volume evaluates the water-equivalent radiological depth:

    d_eff(r) = int_{s_skin}^r rho_e(s') ds'

## 3. Collapsed Cone Convolution Superposition (CCCS)

Absorbed dose D(r) is evaluated by convolving 3D TERMA with polyenergetic point spread energy deposition kernels A(r - r', rho):

    D(r) = (1 / rho(r)) * int_V T(r') * A(r - r', rho_bar) d^3r'

The analytical point-spread kernel is parameterized using the Mack-Papanikolaou and Ahnesjo formulation:

    A(r, theta) = (A_theta / r^2) * [ a_theta * exp(-alpha_theta * r) + b_theta * exp(-beta_theta * r) ]

Spherical 4pi solid angle space is partitioned into M discrete coaxial cones (128 directions using Fibonacci spherical quadrature). Along each cone axis, radiant energy undergoes exponential transport:

    Phi_ray(s + ds) = Phi_ray(s) * exp(-mu_eff * ds) + T(s) * ds
    Delta_D(s) = Phi_ray(s) * mu_eff * ds

Tissue heterogeneities are scaled via O'Connor's theorem:

    A_medium(r) = (rho_e)^2 * A_water(r * rho_e)

## 4. Discrete Ordinates (S_N) Linear Boltzmann Transport

The steady-state multigroup linear Boltzmann transport equation for coupled photon-electron flux psi_g(r, Omega) is solved over Cartesian grids:

    Omega * nabla psi_g(r, Omega) + Sigma_{t,g}(r) * psi_g(r, Omega) =
        sum_{g'} int_{4pi} Sigma_{s,g' -> g}(r, Omega' * Omega) * psi_{g'}(r, Omega') dOmega' + Q_g(r, Omega)

Kerma's compute shader solves the upwind diamond difference balance equation:

    |mu|/dx * (psi_{x,out} - psi_{x,in}) +
    |eta|/dy * (psi_{y,out} - psi_{y,in}) +
    |xi|/dz * (psi_{z,out} - psi_{z,in}) + Sigma_t * psi_cell = Q_source

Unconditional numerical stability is guaranteed through positive flux fixup.

## 5. Proton Bragg Peak and Multiple Coulomb Scattering

Proton depth dose curves are evaluated using the Bortfeld (1997) closed-form analytical model:

    D_bp(z) = [ Phi_0 / (1 + 0.012 * R_0) ] * [ (R_0 - z)^(-1/p) * (1 + 0.012 * z) + ... ]

with range straggling standard deviation sigma_mono = 0.012 * R_0^0.935 and Bragg-Kleeman exponent p = 1.77.

Lateral beam broadening via Multiple Coulomb Scattering (MCS) follows the Fermi-Eyges transport envelope:

    sigma_r^2(z) = sigma_init^2 + (1/3) * T * z^3

where scattering power T(z) is evaluated using Highland's formula:

    T(z) = (14.1 / (p * v))^2 * (1 / X_0)

## 6. AAPM TG-43 Brachytherapy Formalism

The absorbed dose rate from encapsulated radioactive seeds (Ir-192, I-125, Pd-103) is evaluated following AAPM TG-43:

    D_dot(r, theta) = S_K * Lambda * [ G_L(r, theta) / G_L(r_0, theta_0) ] * g_L(r) * F(r, theta)

where:
- S_K is air-kerma strength (U = muGy * m^2 / h).
- Lambda is dose rate constant (cGy / h / U).
- G_L(r, theta) is the line-source geometry factor: beta / (L * r * sin(theta)).
- g_L(r) is the radial dose polynomial function.
- F(r, theta) is the 2D seed anisotropy polynomial function.

## 7. Low's 3D Gamma Index (gamma-Index)

Quantitative agreement between measured dose D_m(r_m) and calculated dose D_c(r_c) is evaluated following Low et al. (1998) and AAPM TG-218:

    Gamma(r_m, r_c) = sqrt( |r_m - r_c|^2 / DTA^2 + (D_m(r_m) - D_c(r_c))^2 / Delta_D^2 )
    gamma(r_m) = min_{r_c} Gamma(r_m, r_c)

A voxel satisfies clinical verification criteria if gamma(r_m) <= 1.0.

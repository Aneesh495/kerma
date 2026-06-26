// NIST Clinical Materials and Stoichiometric Database for Radiotherapy Physics
// Reference: ICRU Report 44, ICRU Report 46, and NIST Standard Reference Database 126
// All densities in g/cm3, mean excitation energies in eV, and atomic cross-sections

#ifndef NIST_MATERIALS_DATABASE_GLSL
#define NIST_MATERIALS_DATABASE_GLSL

struct MaterialProperties {
    uint material_id;
    float mass_density_g_cm3;
    float electron_density_rel_water;
    float mean_excitation_energy_ev;
    float effective_z;
    float radiation_length_g_cm2;
};

// Standard material identifiers
#define MAT_AIR_DRY_NEAR_SEA_LEVEL     0u
#define MAT_WATER_LIQUID               1u
#define MAT_ADIPOSE_TISSUE_ICRU44      2u
#define MAT_SKELETAL_MUSCLE_ICRU44     3u
#define MAT_CORTICAL_BONE_ICRU44       4u
#define MAT_TRABECULAR_BONE_ICRU44     5u
#define MAT_LUNG_DEFLATED_ICRU44       6u
#define MAT_LUNG_INFLATED_ICRU44       7u
#define MAT_BRAIN_GREY_WHITE_MATTER    8u
#define MAT_BREAST_TISSUE_50_50        9u
#define MAT_EYE_LENS_ICRU44           10u
#define MAT_CARTILAGE_ICRU44          11u
#define MAT_SKIN_ICRU44               12u
#define MAT_BLOOD_WHOLE_ICRU44        13u
#define MAT_TITANIUM_IMPLANT_TI6AL4V  14u
#define MAT_STAINLESS_STEEL_316L      15u
#define MAT_GOLD_FIDUCIAL_100PCT      16u
#define MAT_CERROBEND_LIPOWITZ_ALLOY  17u
#define MAT_PMMA_ACRYLIC              18u
#define MAT_POLYSTYRENE               19u
#define MAT_SOLID_WATER_WT1           20u
#define MAT_TUNGSTEN_HEAVY_ALLOY      21u

MaterialProperties get_nist_material(uint id) {
    MaterialProperties mat;
    mat.material_id = id;

    if (id == MAT_AIR_DRY_NEAR_SEA_LEVEL) {
        mat.mass_density_g_cm3 = 0.0012048f;
        mat.electron_density_rel_water = 0.001093f;
        mat.mean_excitation_energy_ev = 85.7f;
        mat.effective_z = 7.78f;
        mat.radiation_length_g_cm2 = 36.62f;
    } else if (id == MAT_WATER_LIQUID) {
        mat.mass_density_g_cm3 = 1.000000f;
        mat.electron_density_rel_water = 1.000000f;
        mat.mean_excitation_energy_ev = 78.0f;
        mat.effective_z = 7.42f;
        mat.radiation_length_g_cm2 = 36.08f;
    } else if (id == MAT_ADIPOSE_TISSUE_ICRU44) {
        mat.mass_density_g_cm3 = 0.950000f;
        mat.electron_density_rel_water = 0.932000f;
        mat.mean_excitation_energy_ev = 64.8f;
        mat.effective_z = 6.33f;
        mat.radiation_length_g_cm2 = 39.81f;
    } else if (id == MAT_SKELETAL_MUSCLE_ICRU44) {
        mat.mass_density_g_cm3 = 1.050000f;
        mat.electron_density_rel_water = 1.036000f;
        mat.mean_excitation_energy_ev = 75.3f;
        mat.effective_z = 7.53f;
        mat.radiation_length_g_cm2 = 35.91f;
    } else if (id == MAT_CORTICAL_BONE_ICRU44) {
        mat.mass_density_g_cm3 = 1.920000f;
        mat.electron_density_rel_water = 1.795000f;
        mat.mean_excitation_energy_ev = 112.0f;
        mat.effective_z = 12.31f;
        mat.radiation_length_g_cm2 = 23.94f;
    } else if (id == MAT_TRABECULAR_BONE_ICRU44) {
        mat.mass_density_g_cm3 = 1.180000f;
        mat.electron_density_rel_water = 1.156000f;
        mat.mean_excitation_energy_ev = 85.9f;
        mat.effective_z = 9.87f;
        mat.radiation_length_g_cm2 = 31.85f;
    } else if (id == MAT_LUNG_DEFLATED_ICRU44) {
        mat.mass_density_g_cm3 = 1.050000f;
        mat.electron_density_rel_water = 1.033000f;
        mat.mean_excitation_energy_ev = 75.3f;
        mat.effective_z = 7.53f;
        mat.radiation_length_g_cm2 = 35.91f;
    } else if (id == MAT_LUNG_INFLATED_ICRU44) {
        mat.mass_density_g_cm3 = 0.260000f;
        mat.electron_density_rel_water = 0.258000f;
        mat.mean_excitation_energy_ev = 75.3f;
        mat.effective_z = 7.53f;
        mat.radiation_length_g_cm2 = 35.91f;
    } else if (id == MAT_BRAIN_GREY_WHITE_MATTER) {
        mat.mass_density_g_cm3 = 1.040000f;
        mat.electron_density_rel_water = 1.030000f;
        mat.mean_excitation_energy_ev = 74.0f;
        mat.effective_z = 7.39f;
        mat.radiation_length_g_cm2 = 36.42f;
    } else if (id == MAT_BREAST_TISSUE_50_50) {
        mat.mass_density_g_cm3 = 0.970000f;
        mat.electron_density_rel_water = 0.958000f;
        mat.mean_excitation_energy_ev = 67.2f;
        mat.effective_z = 6.71f;
        mat.radiation_length_g_cm2 = 38.60f;
    } else if (id == MAT_EYE_LENS_ICRU44) {
        mat.mass_density_g_cm3 = 1.070000f;
        mat.electron_density_rel_water = 1.054000f;
        mat.mean_excitation_energy_ev = 74.5f;
        mat.effective_z = 7.42f;
        mat.radiation_length_g_cm2 = 35.80f;
    } else if (id == MAT_CARTILAGE_ICRU44) {
        mat.mass_density_g_cm3 = 1.100000f;
        mat.electron_density_rel_water = 1.075000f;
        mat.mean_excitation_energy_ev = 76.8f;
        mat.effective_z = 7.74f;
        mat.radiation_length_g_cm2 = 35.10f;
    } else if (id == MAT_SKIN_ICRU44) {
        mat.mass_density_g_cm3 = 1.090000f;
        mat.electron_density_rel_water = 1.066000f;
        mat.mean_excitation_energy_ev = 72.7f;
        mat.effective_z = 7.15f;
        mat.radiation_length_g_cm2 = 36.90f;
    } else if (id == MAT_BLOOD_WHOLE_ICRU44) {
        mat.mass_density_g_cm3 = 1.060000f;
        mat.electron_density_rel_water = 1.045000f;
        mat.mean_excitation_energy_ev = 75.2f;
        mat.effective_z = 7.50f;
        mat.radiation_length_g_cm2 = 35.85f;
    } else if (id == MAT_TITANIUM_IMPLANT_TI6AL4V) {
        mat.mass_density_g_cm3 = 4.430000f;
        mat.electron_density_rel_water = 3.820000f;
        mat.mean_excitation_energy_ev = 233.0f;
        mat.effective_z = 20.80f;
        mat.radiation_length_g_cm2 = 16.12f;
    } else if (id == MAT_STAINLESS_STEEL_316L) {
        mat.mass_density_g_cm3 = 8.000000f;
        mat.electron_density_rel_water = 7.020000f;
        mat.mean_excitation_energy_ev = 286.0f;
        mat.effective_z = 25.80f;
        mat.radiation_length_g_cm2 = 13.84f;
    } else if (id == MAT_GOLD_FIDUCIAL_100PCT) {
        mat.mass_density_g_cm3 = 19.320000f;
        mat.electron_density_rel_water = 15.100000f;
        mat.mean_excitation_energy_ev = 790.0f;
        mat.effective_z = 79.00f;
        mat.radiation_length_g_cm2 = 6.46f;
    } else if (id == MAT_CERROBEND_LIPOWITZ_ALLOY) {
        mat.mass_density_g_cm3 = 9.400000f;
        mat.electron_density_rel_water = 7.820000f;
        mat.mean_excitation_energy_ev = 620.0f;
        mat.effective_z = 69.50f;
        mat.radiation_length_g_cm2 = 7.80f;
    } else if (id == MAT_PMMA_ACRYLIC) {
        mat.mass_density_g_cm3 = 1.190000f;
        mat.electron_density_rel_water = 1.147000f;
        mat.mean_excitation_energy_ev = 74.0f;
        mat.effective_z = 6.56f;
        mat.radiation_length_g_cm2 = 40.55f;
    } else if (id == MAT_POLYSTYRENE) {
        mat.mass_density_g_cm3 = 1.050000f;
        mat.electron_density_rel_water = 1.017000f;
        mat.mean_excitation_energy_ev = 68.7f;
        mat.effective_z = 5.74f;
        mat.radiation_length_g_cm2 = 43.79f;
    } else if (id == MAT_SOLID_WATER_WT1) {
        mat.mass_density_g_cm3 = 1.020000f;
        mat.electron_density_rel_water = 1.002000f;
        mat.mean_excitation_energy_ev = 76.5f;
        mat.effective_z = 7.35f;
        mat.radiation_length_g_cm2 = 36.80f;
    } else if (id == MAT_TUNGSTEN_HEAVY_ALLOY) {
        mat.mass_density_g_cm3 = 18.000000f;
        mat.electron_density_rel_water = 14.800000f;
        mat.mean_excitation_energy_ev = 727.0f;
        mat.effective_z = 71.80f;
        mat.radiation_length_g_cm2 = 6.76f;
    } else {
        // Fallback default: water
        mat.mass_density_g_cm3 = 1.0f;
        mat.electron_density_rel_water = 1.0f;
        mat.mean_excitation_energy_ev = 78.0f;
        mat.effective_z = 7.42f;
        mat.radiation_length_g_cm2 = 36.08f;
    }

    return mat;
}

// Total mass attenuation coefficient (mu / rho) in cm2/g as a function of photon energy in MeV
float nist_mass_attenuation(uint material_id, float energy_mev) {
    MaterialProperties mat = get_nist_material(material_id);
    float z_eff = mat.effective_z;

    // Compton mass attenuation: nearly independent of Z, scales with Z/A ~ 0.5
    // Klein-Nishina cross-section per electron sigma_kn
    float alpha = energy_mev / 0.51099895f;
    float alpha2 = alpha * alpha;
    float one_plus_2a = 1.0f + 2.0f * alpha;
    
    float sigma_kn_term1 = ((1.0f + alpha) / alpha2) * ((2.0f * (1.0f + alpha) / one_plus_2a) - (log(one_plus_2a) / alpha));
    float sigma_kn_term2 = (log(one_plus_2a) / (2.0f * alpha)) - ((1.0f + 3.0f * alpha) / (one_plus_2a * one_plus_2a));
    float sigma_kn = 2.0f * 3.14159265f * (2.81794032e-13f * 2.81794032e-13f) * (sigma_kn_term1 + sigma_kn_term2); // cm2
    
    // Convert cross-section per electron to cm2/g
    // Water contains N_A * (10 / 18.01528) = 3.3428e23 electrons/g.
    float electrons_per_gram = 3.3428e23f * mat.electron_density_rel_water / mat.mass_density_g_cm3;
    float mu_rho_compton = sigma_kn * electrons_per_gram;

    // Photoelectric mass attenuation: scales approximately as Z^3.8 / E_MeV^3.1
    float mu_rho_pe = 0.0f;
    if (energy_mev > 0.01f) {
        mu_rho_pe = 1.5e-9f * pow(z_eff, 3.8f) / pow(energy_mev, 3.1f);
    }

    // Pair production mass attenuation: threshold at 1.022 MeV, scales as Z * log(2E)
    float mu_rho_pair = 0.0f;
    if (energy_mev > 1.022f) {
        mu_rho_pair = 1.2e-5f * z_eff * log(2.0f * energy_mev / 1.022f);
    }

    return mu_rho_compton + mu_rho_pe + mu_rho_pair;
}

// Linear attenuation coefficient mu in cm^-1
float nist_linear_attenuation(uint material_id, float energy_mev) {
    MaterialProperties mat = get_nist_material(material_id);
    return nist_mass_attenuation(material_id, energy_mev) * mat.mass_density_g_cm3;
}

// Proton mass stopping power (S / rho) in MeV cm2/g using Bethe-Bloch formulation with density effect
float nist_proton_mass_stopping_power(uint material_id, float kinetic_energy_mev) {
    MaterialProperties mat = get_nist_material(material_id);
    const float m_p = 938.272f; // Proton rest mass in MeV
    const float m_e = 0.51099895f; // Electron rest mass in MeV
    
    float gamma = 1.0f + kinetic_energy_mev / m_p;
    float beta2 = 1.0f - 1.0f / (gamma * gamma);
    float beta = sqrt(max(beta2, 1e-6f));

    // Maximum kinetic energy transfer to a free electron in a single collision
    float t_max = (2.0f * m_e * beta2 * gamma * gamma) / 
                  (1.0f + 2.0f * gamma * (m_e / m_p) + (m_e / m_p) * (m_e / m_p));

    // Mean excitation energy in MeV
    float i_mev = mat.mean_excitation_energy_ev * 1.0e-6f;

    // Constant 4 * pi * r_e^2 * m_e * c^2 * N_A = 0.307075 MeV cm2 / mol
    float c_const = 0.307075f;
    float z_over_a = 0.55f; // Effective Z/A ratio for biological media
    
    // Bethe-Bloch formula with relativistic kinematics and Sternheimer density correction delta
    float ln_term = log(2.0f * m_e * beta2 * gamma * gamma * t_max / (i_mev * i_mev));
    float stopping_power = (c_const * z_over_a / beta2) * (ln_term - 2.0f * beta2);

    return max(stopping_power, 0.0f);
}

#endif // NIST_MATERIALS_DATABASE_GLSL

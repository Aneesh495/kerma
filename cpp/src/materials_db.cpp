#include "kerma/materials_db.hpp"
#include <algorithm>
#include <cmath>

namespace kerma {

const std::vector<MaterialEntry>& MaterialsDatabase::all_materials() {
    static const std::vector<MaterialEntry> entries = {
        {0,  "Air_Dry_Sea_Level",        0.0012048f, 0.001093f,  85.7f,  7.78f, 36.62f},
        {1,  "Water_Liquid",             1.0000000f, 1.000000f,  78.0f,  7.42f, 36.08f},
        {2,  "Adipose_Tissue_ICRU44",    0.9500000f, 0.932000f,  64.8f,  6.33f, 39.81f},
        {3,  "Skeletal_Muscle_ICRU44",   1.0500000f, 1.036000f,  75.3f,  7.53f, 35.91f},
        {4,  "Cortical_Bone_ICRU44",     1.9200000f, 1.795000f, 112.0f, 12.31f, 23.94f},
        {5,  "Trabecular_Bone_ICRU44",   1.1800000f, 1.156000f,  85.9f,  9.87f, 31.85f},
        {6,  "Lung_Deflated_ICRU44",     1.0500000f, 1.033000f,  75.3f,  7.53f, 35.91f},
        {7,  "Lung_Inflated_ICRU44",     0.2600000f, 0.258000f,  75.3f,  7.53f, 35.91f},
        {8,  "Brain_Grey_White_Matter",  1.0400000f, 1.030000f,  74.0f,  7.39f, 36.42f},
        {9,  "Breast_Tissue_50_50",      0.9700000f, 0.958000f,  67.2f,  6.71f, 38.60f},
        {10, "Eye_Lens_ICRU44",          1.0700000f, 1.054000f,  74.5f,  7.42f, 35.80f},
        {11, "Cartilage_ICRU44",         1.1000000f, 1.075000f,  76.8f,  7.74f, 35.10f},
        {12, "Skin_ICRU44",              1.0900000f, 1.066000f,  72.7f,  7.15f, 36.90f},
        {13, "Blood_Whole_ICRU44",       1.0600000f, 1.045000f,  75.2f,  7.50f, 35.85f},
        {14, "Titanium_Implant_Ti6Al4V", 4.4300000f, 3.820000f, 233.0f, 20.80f, 16.12f},
        {15, "Stainless_Steel_316L",     8.0000000f, 7.020000f, 286.0f, 25.80f, 13.84f},
        {16, "Gold_Fiducial_100pct",     19.320000f, 15.10000f, 790.0f, 79.00f,  6.46f},
        {17, "Cerrobend_Lipowitz_Alloy", 9.4000000f, 7.820000f, 620.0f, 69.50f,  7.80f},
        {18, "PMMA_Acrylic",             1.1900000f, 1.147000f,  74.0f,  6.56f, 40.55f},
        {19, "Polystyrene",              1.0500000f, 1.017000f,  68.7f,  5.74f, 43.79f},
        {20, "Solid_Water_WT1",          1.0200000f, 1.002000f,  76.5f,  7.35f, 36.80f},
        {21, "Tungsten_Heavy_Alloy",     18.000000f, 14.80000f, 727.0f, 71.80f,  6.76f}
    };
    return entries;
}

MaterialEntry MaterialsDatabase::lookup_by_id(uint32_t id) {
    const auto& mats = all_materials();
    if (id < mats.size()) {
        return mats[id];
    }
    return mats[1]; // Default to Liquid Water
}

MaterialEntry MaterialsDatabase::lookup_by_hu(float hu) {
    if (hu < -900.0f) return lookup_by_id(0);  // Air
    if (hu < -200.0f) return lookup_by_id(7);  // Lung inflated
    if (hu < -30.0f)  return lookup_by_id(2);  // Adipose
    if (hu < 20.0f)   return lookup_by_id(1);  // Water
    if (hu < 100.0f)  return lookup_by_id(3);  // Skeletal muscle
    if (hu < 400.0f)  return lookup_by_id(5);  // Trabecular bone
    if (hu < 2500.0f) return lookup_by_id(4);  // Cortical bone
    return lookup_by_id(14);                   // Metallic implant (Titanium)
}

float MaterialsDatabase::mass_attenuation_cm2_g(uint32_t material_id, float energy_mev) {
    MaterialEntry mat = lookup_by_id(material_id);
    float z_eff = mat.effective_z;

    float alpha = energy_mev / 0.51099895f;
    float alpha2 = alpha * alpha;
    float one_plus_2a = 1.0f + 2.0f * alpha;

    float sigma_kn_term1 = ((1.0f + alpha) / alpha2) *
                           ((2.0f * (1.0f + alpha) / one_plus_2a) - (std::log(one_plus_2a) / alpha));
    float sigma_kn_term2 = (std::log(one_plus_2a) / (2.0f * alpha)) -
                           ((1.0f + 3.0f * alpha) / (one_plus_2a * one_plus_2a));
    float sigma_kn = 2.0f * 3.14159265f * (2.81794032e-13f * 2.81794032e-13f) *
                     (sigma_kn_term1 + sigma_kn_term2);

    // Water contains N_A * (10 / 18.01528) = 3.3428e23 electrons/g.
    // Scaling by (electron_density_rel_water / mass_density_g_cm3) yields electrons/g for any medium.
    float electrons_per_gram = 3.3428e23f * mat.electron_density_rel_water / mat.mass_density_g_cm3;
    float mu_rho_compton = sigma_kn * electrons_per_gram;

    float mu_rho_pe = 0.0f;
    if (energy_mev > 0.01f) {
        mu_rho_pe = 1.5e-9f * std::pow(z_eff, 3.8f) / std::pow(energy_mev, 3.1f);
    }

    float mu_rho_pair = 0.0f;
    if (energy_mev > 1.022f) {
        mu_rho_pair = 1.2e-5f * z_eff * std::log(2.0f * energy_mev / 1.022f);
    }

    return mu_rho_compton + mu_rho_pe + mu_rho_pair;
}

float MaterialsDatabase::proton_stopping_power_mev_cm2_g(uint32_t material_id, float kinetic_energy_mev) {
    MaterialEntry mat = lookup_by_id(material_id);
    constexpr float m_p = 938.272f;
    constexpr float m_e = 0.51099895f;

    float gamma = 1.0f + kinetic_energy_mev / m_p;
    float beta2 = 1.0f - 1.0f / (gamma * gamma);
    beta2 = std::max(beta2, 1e-6f);

    float t_max = (2.0f * m_e * beta2 * gamma * gamma) /
                  (1.0f + 2.0f * gamma * (m_e / m_p) + (m_e / m_p) * (m_e / m_p));

    float i_mev = mat.mean_excitation_energy_ev * 1.0e-6f;
    constexpr float c_const = 0.307075f;
    constexpr float z_over_a = 0.55f;

    float ln_term = std::log(2.0f * m_e * beta2 * gamma * gamma * t_max / (i_mev * i_mev));
    float stopping_power = (c_const * z_over_a / beta2) * (ln_term - 2.0f * beta2);

    return std::max(stopping_power, 0.0f);
}

} // namespace kerma

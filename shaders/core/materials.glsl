/**
 * Kerma Radiation Oncology Simulation Engine
 * Stoichiometric biological tissue definitions and NIST radiation interaction data
 * based on ICRU Reports 44/46 and Schneider et al. (2000).
 */

#ifndef KERMA_MATERIALS_GLSL
#define KERMA_MATERIALS_GLSL

#include "constants.glsl"

#define MATERIAL_AIR            0
#define MATERIAL_LUNG_INFLATED  1
#define MATERIAL_LUNG_DEFLATED  2
#define MATERIAL_ADIPOSE        3
#define MATERIAL_WATER          4
#define MATERIAL_MUSCLE         5
#define MATERIAL_CARTILAGE      6
#define MATERIAL_TRABECULAR_BONE 7
#define MATERIAL_CORTICAL_BONE  8
#define MATERIAL_TITANIUM       9
#define MATERIAL_COUNT          10

struct TissueProperties {
    float mass_density_g_cm3;   // Physical mass density (rho)
    float relative_electron_dens;// Electron density relative to water (rho_e)
    float effective_z;          // Effective atomic number (Z_eff)
    float mean_excitation_ev;   // Mean excitation potential (I-value in eV)
    float mu_en_over_rho_6mv;   // Mass energy-absorption coeff at 6 MV (cm^2 / g)
    float mu_en_over_rho_10mv;  // Mass energy-absorption coeff at 10 MV (cm^2 / g)
    float mu_en_over_rho_15mv;  // Mass energy-absorption coeff at 15 MV (cm^2 / g)
    float proton_stopping_power;// Nominal proton stopping power relative to water
};

/**
 * Returns calibrated radiological properties for standard anatomical materials.
 */
TissueProperties getTissueProperties(int material_id) {
    TissueProperties mat;
    
    if (material_id == MATERIAL_AIR) {
        mat.mass_density_g_cm3    = 0.001205;
        mat.relative_electron_dens= 0.001;
        mat.effective_z           = 7.78;
        mat.mean_excitation_ev    = 85.7;
        mat.mu_en_over_rho_6mv    = 0.0268;
        mat.mu_en_over_rho_10mv   = 0.0232;
        mat.mu_en_over_rho_15mv   = 0.0205;
        mat.proton_stopping_power = 0.001;
    } else if (material_id == MATERIAL_LUNG_INFLATED) {
        mat.mass_density_g_cm3    = 0.260;
        mat.relative_electron_dens= 0.258;
        mat.effective_z           = 7.55;
        mat.mean_excitation_ev    = 75.3;
        mat.mu_en_over_rho_6mv    = 0.0279;
        mat.mu_en_over_rho_10mv   = 0.0241;
        mat.mu_en_over_rho_15mv   = 0.0213;
        mat.proton_stopping_power = 0.260;
    } else if (material_id == MATERIAL_LUNG_DEFLATED) {
        mat.mass_density_g_cm3    = 0.500;
        mat.relative_electron_dens= 0.495;
        mat.effective_z           = 7.55;
        mat.mean_excitation_ev    = 75.3;
        mat.mu_en_over_rho_6mv    = 0.0279;
        mat.mu_en_over_rho_10mv   = 0.0241;
        mat.mu_en_over_rho_15mv   = 0.0213;
        mat.proton_stopping_power = 0.498;
    } else if (material_id == MATERIAL_ADIPOSE) {
        mat.mass_density_g_cm3    = 0.950;
        mat.relative_electron_dens= 0.932;
        mat.effective_z           = 6.46;
        mat.mean_excitation_ev    = 63.2;
        mat.mu_en_over_rho_6mv    = 0.0276;
        mat.mu_en_over_rho_10mv   = 0.0238;
        mat.mu_en_over_rho_15mv   = 0.0210;
        mat.proton_stopping_power = 0.945;
    } else if (material_id == MATERIAL_WATER) {
        mat.mass_density_g_cm3    = 1.000;
        mat.relative_electron_dens= 1.000;
        mat.effective_z           = 7.42;
        mat.mean_excitation_ev    = 75.0;
        mat.mu_en_over_rho_6mv    = 0.0278;
        mat.mu_en_over_rho_10mv   = 0.0240;
        mat.mu_en_over_rho_15mv   = 0.0212;
        mat.proton_stopping_power = 1.000;
    } else if (material_id == MATERIAL_MUSCLE) {
        mat.mass_density_g_cm3    = 1.050;
        mat.relative_electron_dens= 1.040;
        mat.effective_z           = 7.64;
        mat.mean_excitation_ev    = 75.0;
        mat.mu_en_over_rho_6mv    = 0.0278;
        mat.mu_en_over_rho_10mv   = 0.0240;
        mat.mu_en_over_rho_15mv   = 0.0212;
        mat.proton_stopping_power = 1.035;
    } else if (material_id == MATERIAL_CARTILAGE) {
        mat.mass_density_g_cm3    = 1.100;
        mat.relative_electron_dens= 1.085;
        mat.effective_z           = 7.82;
        mat.mean_excitation_ev    = 76.2;
        mat.mu_en_over_rho_6mv    = 0.0277;
        mat.mu_en_over_rho_10mv   = 0.0239;
        mat.mu_en_over_rho_15mv   = 0.0211;
        mat.proton_stopping_power = 1.078;
    } else if (material_id == MATERIAL_TRABECULAR_BONE) {
        mat.mass_density_g_cm3    = 1.180;
        mat.relative_electron_dens= 1.150;
        mat.effective_z           = 10.20;
        mat.mean_excitation_ev    = 91.9;
        mat.mu_en_over_rho_6mv    = 0.0272;
        mat.mu_en_over_rho_10mv   = 0.0235;
        mat.mu_en_over_rho_15mv   = 0.0208;
        mat.proton_stopping_power = 1.120;
    } else if (material_id == MATERIAL_CORTICAL_BONE) {
        mat.mass_density_g_cm3    = 1.920;
        mat.relative_electron_dens= 1.820;
        mat.effective_z           = 13.80;
        mat.mean_excitation_ev    = 112.0;
        mat.mu_en_over_rho_6mv    = 0.0264;
        mat.mu_en_over_rho_10mv   = 0.0229;
        mat.mu_en_over_rho_15mv   = 0.0203;
        mat.proton_stopping_power = 1.680;
    } else { // MATERIAL_TITANIUM
        mat.mass_density_g_cm3    = 4.540;
        mat.relative_electron_dens= 3.820;
        mat.effective_z           = 22.00;
        mat.mean_excitation_ev    = 233.0;
        mat.mu_en_over_rho_6mv    = 0.0235;
        mat.mu_en_over_rho_10mv   = 0.0210;
        mat.mu_en_over_rho_15mv   = 0.0195;
        mat.proton_stopping_power = 3.250;
    }
    
    return mat;
}

/**
 * Computes energy-dependent Compton linear attenuation coefficient (mu_c in cm^-1).
 * Utilizes the Klein-Nishina cross-section per electron scaled by electron density.
 */
float computeComptonAttenuation(float photon_energy_mev, float relative_electron_dens) {
    float alpha = photon_energy_mev / ELECTRON_REST_MEV;
    if (alpha < 0.001) {
        return relative_electron_dens * 0.19; // Low energy limit
    }
    
    // Klein-Nishina total cross section per electron sigma_KN
    float one_plus_2a = 1.0 + 2.0 * alpha;
    float term1 = (2.0 * (1.0 + alpha) / (alpha * alpha)) *
                  ((one_plus_2a) / (1.0 + 2.0 * alpha) - log(one_plus_2a) / (2.0 * alpha));
    float term2 = log(one_plus_2a) / (2.0 * alpha);
    float term3 = -(1.0 + 3.0 * alpha) / (one_plus_2a * one_plus_2a);
    
    float sigma_kn_ratio = 0.75 * (term1 + term2 + term3) / alpha;
    
    // Scale by water reference linear attenuation (approx 0.063 cm^-1 at 1 MeV)
    float base_mu = 0.0635 * sigma_kn_ratio;
    return base_mu * relative_electron_dens;
}

#endif // KERMA_MATERIALS_GLSL

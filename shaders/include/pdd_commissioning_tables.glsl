// Clinical Linear Accelerator Percent Depth Dose (PDD) and Output Factor Commissioning Tables
// Reference: British Journal of Radiology Supplement 25 & AAPM TG-106 Beam Data Commissioning
// Nominal SSD = 100.0 cm, Field Size Equivalence (Sterling A/P method)

#ifndef PDD_COMMISSIONING_TABLES_GLSL
#define PDD_COMMISSIONING_TABLES_GLSL

#define BEAM_ENERGY_6MV   0u
#define BEAM_ENERGY_10MV  1u
#define BEAM_ENERGY_15MV  2u
#define BEAM_ENERGY_6FFF  3u

struct BeamCommissioningData {
    float d_max_mm;
    float pdd_10cm_10x10;      // Quality index metric PDD(10) at 10x10 cm2
    float tpr_20_10;           // Beam quality specifier TPR20/10
    float surface_dose_pct;    // Percentage dose at z = 0 mm
    float mu_eff_mm1;          // Effective exponential attenuation coefficient
};

BeamCommissioningData get_beam_commissioning_data(uint beam_energy_id) {
    BeamCommissioningData b;
    if (beam_energy_id == BEAM_ENERGY_6MV) {
        b.d_max_mm = 15.0f;
        b.pdd_10cm_10x10 = 66.8f;
        b.tpr_20_10 = 0.672f;
        b.surface_dose_pct = 28.0f;
        b.mu_eff_mm1 = 0.00485f;
    } else if (beam_energy_id == BEAM_ENERGY_10MV) {
        b.d_max_mm = 24.0f;
        b.pdd_10cm_10x10 = 73.2f;
        b.tpr_20_10 = 0.741f;
        b.surface_dose_pct = 21.0f;
        b.mu_eff_mm1 = 0.00382f;
    } else if (beam_energy_id == BEAM_ENERGY_15MV) {
        b.d_max_mm = 30.0f;
        b.pdd_10cm_10x10 = 76.8f;
        b.tpr_20_10 = 0.764f;
        b.surface_dose_pct = 17.5f;
        b.mu_eff_mm1 = 0.00338f;
    } else {
        // 6 MV FFF (Flattening Filter Free): softer spectrum due to lack of filter beam hardening
        b.d_max_mm = 14.0f;
        b.pdd_10cm_10x10 = 63.4f;
        b.tpr_20_10 = 0.642f;
        b.surface_dose_pct = 34.0f;
        b.mu_eff_mm1 = 0.00532f;
    }
    return b;
}

// Compute equivalent square field size (mm) using Sterling Area-to-Perimeter formula
float equivalent_square_field_mm(float width_x_mm, float length_y_mm) {
    float denom = max(width_x_mm + length_y_mm, 1.0f);
    return (2.0f * width_x_mm * length_y_mm) / denom;
}

// Evaluate total scatter factor S_cp = S_c * S_p as function of equivalent square field s (mm)
float evaluate_total_scatter_factor(uint beam_energy_id, float eq_sq_mm) {
    float s_cm = clamp(eq_sq_mm * 0.1f, 2.0f, 40.0f);
    // Reference 10x10 cm2 field gives S_cp = 1.000
    float log_ratio = log(s_cm / 10.0f);

    float slope = 0.042f;
    if (beam_energy_id == BEAM_ENERGY_10MV) slope = 0.036f;
    else if (beam_energy_id == BEAM_ENERGY_15MV) slope = 0.031f;
    else if (beam_energy_id == BEAM_ENERGY_6FFF) slope = 0.034f; // Reduced head scatter without filter

    return clamp(1.0f + slope * log_ratio, 0.78f, 1.15f);
}

// Evaluate calibrated Percentage Depth Dose PDD(z, s) normalized to 100% at d_max
float evaluate_commissioned_pdd(uint beam_energy_id, float depth_mm, float eq_sq_mm, float ssd_mm) {
    BeamCommissioningData b = get_beam_commissioning_data(beam_energy_id);
    if (depth_mm < 0.0f) return 0.0f;

    float d_max = b.d_max_mm;
    if (depth_mm <= d_max) {
        // Electronic disequilibrium buildup region modeled by exponential saturation
        float tau = 3.2f / max(d_max, 1.0f);
        float buildup = 1.0f - exp(-tau * depth_mm);
        float buildup_norm = 1.0f - exp(-tau * d_max);
        float norm_b = buildup / max(buildup_norm, 1e-4f);
        return mix(b.surface_dose_pct, 100.0f, norm_b);
    }

    // Beyond d_max: primary exponential attenuation + phantom scatter + Mayneord inverse square falloff
    float s_cm = clamp(eq_sq_mm * 0.1f, 2.0f, 40.0f);
    float scatter_softening = 1.0f - 0.008f * (s_cm - 10.0f);
    float mu_eff = b.mu_eff_mm1 * clamp(scatter_softening, 0.75f, 1.25f);

    float dz = depth_mm - d_max;
    float exp_falloff = exp(-mu_eff * dz);

    // Inverse-square divergence factor relative to (SSD + d_max)
    float inv_sq = pow((ssd_mm + d_max) / (ssd_mm + depth_mm), 2.0f);

    return 100.0f * exp_falloff * inv_sq;
}

#endif // PDD_COMMISSIONING_TABLES_GLSL

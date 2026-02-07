/**
 * Kerma Radiation Oncology Simulation Engine
 * Physical constants, radiation dosimetry units, and mathematical definitions.
 *
 * All units follow standard radiation therapy physics conventions:
 * - Length: millimeters (mm)
 * - Energy: mega-electronvolts (MeV)
 * - Absorbed Dose: Gray (Gy = J / kg)
 * - Time: seconds (s)
 * - Density: grams per cubic centimeter (g / cm^3)
 */

#ifndef KERMA_CONSTANTS_GLSL
#define KERMA_CONSTANTS_GLSL

// Mathematical Constants
const float PI                  = 3.14159265358979323846;
const float TWO_PI              = 6.28318530717958647692;
const float HALF_PI             = 1.57079632679489661923;
const float INV_PI              = 0.31830988618379067154;
const float INV_TWO_PI          = 0.15915494309189533577;
const float FOUR_PI             = 12.56637061435917295385;
const float INV_FOUR_PI         = 0.07957747154594766788;
const float SQRT_TWO            = 1.41421356237309504880;
const float INV_SQRT_TWO        = 0.70710678118654752440;
const float SQRT_THREE          = 1.73205080756887729353;
const float LN_TWO              = 0.69314718055994530942;
const float DEG_TO_RAD          = 0.01745329251994329577;
const float RAD_TO_DEG          = 57.2957795130823208768;

// Fundamental Physical Constants (CODATA 2018)
const float SPEED_OF_LIGHT      = 299792458.0;          // m / s
const float PLANCK_CONSTANT     = 6.62607015e-34;       // J * s
const float REDUCED_PLANCK      = 1.054571817e-34;      // J * s (hbar)
const float ELEMENTARY_CHARGE   = 1.602176634e-19;      // C
const float ELECTRON_MASS_KG    = 9.1093837015e-31;     // kg
const float ELECTRON_REST_MEV   = 0.510998950;          // MeV (m_e * c^2)
const float PROTON_REST_MEV     = 938.27208816;         // MeV (m_p * c^2)
const float AVOGADRO_NUMBER     = 6.02214076e23;        // mol^-1
const float CLASSICAL_ELECTRON_R = 2.8179403262e-15;    // m (r_e)
const float THOMSON_CROSS_SECTION = 0.66524587321e-28;  // m^2 (sigma_T)

// Radiation Dosimetry and Energy Conversions
const float JOULE_PER_EV        = 1.602176634e-19;      // J / eV
const float JOULE_PER_MEV       = 1.602176634e-13;      // J / MeV
const float MEV_PER_JOULE       = 6.241509074e12;       // MeV / J
const float GRAY_TO_RAD         = 100.0;                // 1 Gy = 100 cGy = 100 rad
const float ROENTGEN_TO_COULOMB_KG = 2.58e-4;           // C / kg per R

// Standard Water Reference Quantities (TG-51 / TRS-398)
const float WATER_DENSITY_G_CM3 = 1.000;                // g / cm^3 at 20 C
const float WATER_DENSITY_KG_M3 = 1000.0;               // kg / m^3
const float WATER_ELECTRON_DENSITY_PER_CM3 = 3.3428e23; // e- / cm^3
const float WATER_MEAN_EXCITATION_EV = 75.0;            // I-value (eV)
const float WATER_Z_OVER_A      = 0.55509;              // Effective Z/A

// Machine Geometry Reference Defaults (IEC 61217)
const float DEFAULT_SAD_MM      = 1000.0;               // Source-to-Axis Distance (mm)
const float DEFAULT_CALIBRATION_DEPTH_MM = 100.0;       // Reference depth d_max or 10 cm (mm)
const float DEFAULT_SSD_MM      = 900.0;                // Standard 100 cm SAD - 10 cm depth
const float MAX_FIELD_DIM_MM    = 400.0;                // Maximum collimator field size (40 x 40 cm)
const float COLLIMATOR_JAW_MIN_MM = -200.0;             // Minimum jaw position (mm)
const float COLLIMATOR_JAW_MAX_MM = 200.0;              // Maximum jaw position (mm)

// Numeric Tolerances
const float EPSILON_FLOAT       = 1.0e-7;
const float EPSILON_GEOMETRY    = 1.0e-4;               // 0.1 micrometer spatial threshold
const float LARGE_FLOAT         = 1.0e30;

#endif // KERMA_CONSTANTS_GLSL

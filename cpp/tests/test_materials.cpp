#include "kerma/materials_db.hpp"
#include <iostream>
#include <cassert>
#include <cmath>

namespace kerma {

void run_materials_tests() {
    std::cout << "[TEST] Running NIST Materials Database & Stopping Power Tests..." << std::endl;

    // Test 1: Check database completeness
    const auto& all = MaterialsDatabase::all_materials();
    assert(all.size() >= 22);

    // Test 2: Water properties check
    MaterialEntry water = MaterialsDatabase::lookup_by_id(1);
    assert(water.name == "Water_Liquid");
    assert(std::abs(water.mass_density_g_cm3 - 1.0f) < 1e-5f);
    assert(std::abs(water.electron_density_rel_water - 1.0f) < 1e-5f);

    // Test 3: HU mapping consistency
    assert(MaterialsDatabase::lookup_by_hu(-1000.0f).id == 0); // Air
    assert(MaterialsDatabase::lookup_by_hu(-700.0f).id == 7);  // Lung
    assert(MaterialsDatabase::lookup_by_hu(0.0f).id == 1);     // Water
    assert(MaterialsDatabase::lookup_by_hu(1200.0f).id == 4);  // Cortical bone

    // Test 4: Photon mass attenuation for water at 1.25 MeV (Co-60 average)
    // Expected NIST value for water at 1.25 MeV ~ 0.0632 cm2/g
    float mu_rho_water = MaterialsDatabase::mass_attenuation_cm2_g(1, 1.25f);
    assert(mu_rho_water > 0.055f && mu_rho_water < 0.075f);

    // Test 5: Low energy photoelectric dominance in bone vs water (at 0.03 MeV)
    float mu_bone_30kev = MaterialsDatabase::mass_attenuation_cm2_g(4, 0.03f);
    float mu_water_30kev = MaterialsDatabase::mass_attenuation_cm2_g(1, 0.03f);
    assert(mu_bone_30kev > 3.0f * mu_water_30kev);

    // Test 6: Proton Bragg peak rising stopping power as energy decreases
    float s_150mev = MaterialsDatabase::proton_stopping_power_mev_cm2_g(1, 150.0f);
    float s_10mev = MaterialsDatabase::proton_stopping_power_mev_cm2_g(1, 10.0f);
    assert(s_10mev > 5.0f * s_150mev);

    std::cout << "[PASS] All NIST Materials Database Tests Passed!" << std::endl;
}

} // namespace kerma

#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace kerma {

struct MaterialEntry {
    uint32_t id = 1;
    std::string name;
    float mass_density_g_cm3 = 1.0f;
    float electron_density_rel_water = 1.0f;
    float mean_excitation_energy_ev = 78.0f;
    float effective_z = 7.42f;
    float radiation_length_g_cm2 = 36.08f;
};

class MaterialsDatabase {
public:
    static const std::vector<MaterialEntry>& all_materials();
    static MaterialEntry lookup_by_id(uint32_t id);
    static MaterialEntry lookup_by_hu(float hu);

    // Evaluates total photon mass attenuation coefficient (mu/rho) in cm^2/g at photon energy in MeV
    static float mass_attenuation_cm2_g(uint32_t material_id, float energy_mev);

    // Evaluates Bethe-Bloch proton mass stopping power (S/rho) in MeV*cm^2/g
    static float proton_stopping_power_mev_cm2_g(uint32_t material_id, float kinetic_energy_mev);
};

} // namespace kerma

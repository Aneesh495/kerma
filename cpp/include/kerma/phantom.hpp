#ifndef KERMA_PHANTOM_HPP
#define KERMA_PHANTOM_HPP

#include <vector>
#include <string>
#include <cstdint>

namespace kerma {

enum class PhantomType {
    WaterCube,
    ThoraxLungTumor,
    PelvisProstateOAR,
    SlitGeometryQA
};

struct VoxelVolume {
    int nx = 64;
    int ny = 64;
    int nz = 64;
    float dx_mm = 2.5f;
    float dy_mm = 2.5f;
    float dz_mm = 2.5f;
    float origin_x_mm = -80.0f;
    float origin_y_mm = -80.0f;
    float origin_z_mm = -80.0f;

    std::vector<float> hu_data;      // Raw Hounsfield Units (-1000 to +3000)
    std::vector<float> mass_density; // g / cm^3
    std::vector<float> rho_e;        // Relative electron density
    std::vector<int32_t> roi_labels; // 0 = background, 1 = PTV, 2 = OAR1, 3 = OAR2

    [[nodiscard]] size_t index(int x, int y, int z) const {
        return static_cast<size_t>(z * (nx * ny) + y * nx + x);
    }

    [[nodiscard]] float get_hu(int x, int y, int z) const {
        return hu_data[index(x, y, z)];
    }

    [[nodiscard]] float get_density(int x, int y, int z) const {
        return mass_density[index(x, y, z)];
    }

    [[nodiscard]] float get_rho_e(int x, int y, int z) const {
        return rho_e[index(x, y, z)];
    }

    [[nodiscard]] int32_t get_roi(int x, int y, int z) const {
        return roi_labels[index(x, y, z)];
    }
};

/**
 * Generates synthetic anatomical and QA calibration phantoms.
 */
VoxelVolume create_synthetic_phantom(PhantomType type, int nx = 64, int ny = 64, int nz = 64, float pitch_mm = 2.5f);

} // namespace kerma

#endif // KERMA_PHANTOM_HPP

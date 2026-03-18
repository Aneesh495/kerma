#ifndef KERMA_ANALYTICAL_DOSE_HPP
#define KERMA_ANALYTICAL_DOSE_HPP

#include "phantom.hpp"
#include "beam_geometry.hpp"
#include <vector>

namespace kerma {

struct DoseGrid3D {
    int nx = 64;
    int ny = 64;
    int nz = 64;
    float dx_mm = 2.5f;
    float dy_mm = 2.5f;
    float dz_mm = 2.5f;
    float origin_x_mm = -80.0f;
    float origin_y_mm = -80.0f;
    float origin_z_mm = -80.0f;

    std::vector<float> dose_gy; // Physical absorbed dose in Gray

    [[nodiscard]] size_t index(int x, int y, int z) const {
        return static_cast<size_t>(z * (nx * ny) + y * nx + x);
    }

    [[nodiscard]] float get(int x, int y, int z) const {
        return dose_gy[index(x, y, z)];
    }

    void set(int x, int y, int z, float val) {
        dose_gy[index(x, y, z)] = val;
    }

    [[nodiscard]] float max_dose() const {
        float m = 0.0f;
        for (float v : dose_gy) {
            if (v > m) m = v;
        }
        return m;
    }
};

/**
 * Computes 3D analytical pencil beam dose distribution across volume.
 */
DoseGrid3D compute_analytical_pbc_dose(const VoxelVolume& phantom, const BeamParameters& beam);

/**
 * Computes analytical Bortfeld proton Bragg peak depth-dose curve.
 */
std::vector<float> compute_bortfeld_bragg_curve(float range_r0_mm, float energy_spread, int samples, float max_depth_mm);

/**
 * Computes analytical AAPM TG-43 point source brachytherapy dose distribution.
 */
DoseGrid3D compute_tg43_seed_dose(const VoxelVolume& phantom, const Vec3& seed_pos, float air_kerma_strength_sk, float dwell_seconds);

} // namespace kerma

#endif // KERMA_ANALYTICAL_DOSE_HPP

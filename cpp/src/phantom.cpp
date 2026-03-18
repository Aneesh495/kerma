#include "kerma/phantom.hpp"
#include <cmath>

namespace kerma {

VoxelVolume create_synthetic_phantom(PhantomType type, int nx, int ny, int nz, float pitch_mm) {
    VoxelVolume vol;
    vol.nx = nx;
    vol.ny = ny;
    vol.nz = nz;
    vol.dx_mm = pitch_mm;
    vol.dy_mm = pitch_mm;
    vol.dz_mm = pitch_mm;
    vol.origin_x_mm = -0.5f * static_cast<float>(nx) * pitch_mm;
    vol.origin_y_mm = -0.5f * static_cast<float>(ny) * pitch_mm;
    vol.origin_z_mm = -0.5f * static_cast<float>(nz) * pitch_mm;

    size_t total_voxels = static_cast<size_t>(nx * ny * nz);
    vol.hu_data.resize(total_voxels, -1000.0f); // Default to air
    vol.mass_density.resize(total_voxels, 0.0012f);
    vol.rho_e.resize(total_voxels, 0.001f);
    vol.roi_labels.resize(total_voxels, 0);

    for (int z = 0; z < nz; ++z) {
        float pz = vol.origin_z_mm + (static_cast<float>(z) + 0.5f) * pitch_mm;
        for (int y = 0; y < ny; ++y) {
            float py = vol.origin_y_mm + (static_cast<float>(y) + 0.5f) * pitch_mm;
            for (int x = 0; x < nx; ++x) {
                float px = vol.origin_x_mm + (static_cast<float>(x) + 0.5f) * pitch_mm;
                size_t idx = vol.index(x, y, z);

                if (type == PhantomType::WaterCube) {
                    // Standard homogeneous water phantom: 150 x 150 x 150 mm
                    if (std::abs(px) <= 75.0f && std::abs(py) <= 75.0f && std::abs(pz) <= 75.0f) {
                        vol.hu_data[idx] = 0.0f;       // Water
                        vol.mass_density[idx] = 1.000f;
                        vol.rho_e[idx] = 1.000f;
                        // Central cubic PTV target
                        if (std::abs(px) <= 20.0f && std::abs(py) <= 20.0f && std::abs(pz) <= 20.0f) {
                            vol.roi_labels[idx] = 1; // PTV
                        }
                    }
                } else if (type == PhantomType::ThoraxLungTumor) {
                    // Thoracic phantom: body cylinder (R = 70 mm)
                    float r_body = std::sqrt(px * px + py * py);
                    if (r_body <= 70.0f && std::abs(pz) <= 60.0f) {
                        // Tissue chest wall default
                        vol.hu_data[idx] = 40.0f;
                        vol.mass_density[idx] = 1.05f;
                        vol.rho_e[idx] = 1.04f;

                        // Bilateral lung cavities (R = 25 mm centered at x = +/-32 mm)
                        float r_lung_l = std::sqrt((px - 32.0f) * (px - 32.0f) + (py - 5.0f) * (py - 5.0f));
                        float r_lung_r = std::sqrt((px + 32.0f) * (px + 32.0f) + (py - 5.0f) * (py - 5.0f));

                        if (r_lung_l <= 25.0f || r_lung_r <= 25.0f) {
                            vol.hu_data[idx] = -700.0f; // Inflated lung
                            vol.mass_density[idx] = 0.26f;
                            vol.rho_e[idx] = 0.26f;
                            vol.roi_labels[idx] = 3;    // Lung OAR
                        }

                        // Spinal cord and vertebral body (posterior, y = -45 mm)
                        float r_spine = std::sqrt(px * px + (py + 45.0f) * (py + 45.0f));
                        if (r_spine <= 12.0f) {
                            vol.hu_data[idx] = 800.0f; // Trabecular/cortical bone
                            vol.mass_density[idx] = 1.45f;
                            vol.rho_e[idx] = 1.38f;
                            vol.roi_labels[idx] = 2;   // Spinal Cord / Spine OAR
                        }

                        // Spherical tumor target inside left lung (R = 14 mm at x = 32, y = 5, z = 0)
                        float r_tumor = std::sqrt((px - 32.0f) * (px - 32.0f) + (py - 5.0f) * (py - 5.0f) + pz * pz);
                        if (r_tumor <= 14.0f) {
                            vol.hu_data[idx] = 50.0f; // Dense solid tumor
                            vol.mass_density[idx] = 1.06f;
                            vol.rho_e[idx] = 1.05f;
                            vol.roi_labels[idx] = 1;  // PTV Target
                        }
                    }
                } else if (type == PhantomType::PelvisProstateOAR) {
                    // Pelvic phantom: oval body
                    float oval = (px * px) / (75.0f * 75.0f) + (py * py) / (60.0f * 60.0f);
                    if (oval <= 1.0f && std::abs(pz) <= 65.0f) {
                        vol.hu_data[idx] = 35.0f; // Muscle / soft tissue
                        vol.mass_density[idx] = 1.03f;
                        vol.rho_e[idx] = 1.02f;

                        // Prostate central target (R = 18 mm at x = 0, y = 0, z = 0)
                        float r_pros = std::sqrt(px * px + py * py + pz * pz);
                        if (r_pros <= 18.0f) {
                            vol.hu_data[idx] = 45.0f;
                            vol.mass_density[idx] = 1.05f;
                            vol.rho_e[idx] = 1.04f;
                            vol.roi_labels[idx] = 1; // PTV Prostate
                        }

                        // Rectum OAR (posterior, y = -26 mm, R = 11 mm cylinder)
                        float r_rect = std::sqrt(px * px + (py + 26.0f) * (py + 26.0f));
                        if (r_rect <= 11.0f) {
                            vol.hu_data[idx] = 20.0f;
                            vol.mass_density[idx] = 1.01f;
                            vol.rho_e[idx] = 1.00f;
                            vol.roi_labels[idx] = 2; // Rectum OAR
                        }

                        // Bladder OAR (anterior, y = +28 mm, R = 20 mm sphere)
                        float r_blad = std::sqrt(px * px + (py - 28.0f) * (py - 28.0f) + pz * pz);
                        if (r_blad <= 20.0f) {
                            vol.hu_data[idx] = 5.0f; // Urine / water-like
                            vol.mass_density[idx] = 1.00f;
                            vol.rho_e[idx] = 1.00f;
                            vol.roi_labels[idx] = 3; // Bladder OAR
                        }

                        // Femoral heads (bilateral cortical bone, x = +/- 50 mm, y = -10 mm)
                        float r_fem_l = std::sqrt((px - 50.0f) * (px - 50.0f) + (py + 10.0f) * (py + 10.0f));
                        float r_fem_r = std::sqrt((px + 50.0f) * (px + 50.0f) + (py + 10.0f) * (py + 10.0f));
                        if (r_fem_l <= 16.0f || r_fem_r <= 16.0f) {
                            vol.hu_data[idx] = 1100.0f; // Cortical bone
                            vol.mass_density[idx] = 1.75f;
                            vol.rho_e[idx] = 1.62f;
                        }
                    }
                } else {
                    // Slit geometry QA phantom
                    if (std::abs(px) <= 60.0f && std::abs(py) <= 60.0f && std::abs(pz) <= 60.0f) {
                        vol.hu_data[idx] = 0.0f;
                        vol.mass_density[idx] = 1.00f;
                        vol.rho_e[idx] = 1.00f;
                        if (std::abs(px) <= 5.0f) {
                            vol.roi_labels[idx] = 1; // Narrow slit target
                        }
                    }
                }
            }
        }
    }

    return vol;
}

} // namespace kerma

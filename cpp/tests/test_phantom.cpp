#include "kerma/phantom.hpp"
#include <cassert>
#include <iostream>

void test_water_phantom() {
    kerma::VoxelVolume p = kerma::create_synthetic_phantom(kerma::PhantomType::WaterCube, 32, 32, 32, 5.0f);
    assert(p.nx == 32);
    assert(p.ny == 32);
    assert(p.nz == 32);
    assert(p.hu_data.size() == 32 * 32 * 32);

    // Center voxel should be water (HU = 0, rho = 1.0)
    int cx = 16, cy = 16, cz = 16;
    float center_hu = p.get_hu(cx, cy, cz);
    float center_rho = p.get_density(cx, cy, cz);
    assert(std::abs(center_hu - 0.0f) < 1.0e-3f);
    assert(std::abs(center_rho - 1.0f) < 1.0e-3f);
    std::cout << "[PASS] test_water_phantom" << std::endl;
}

void test_thorax_phantom() {
    kerma::VoxelVolume p = kerma::create_synthetic_phantom(kerma::PhantomType::ThoraxLungTumor, 40, 40, 40, 4.0f);
    // Corner voxel should be ambient air
    float corner_hu = p.get_hu(0, 0, 0);
    assert(corner_hu <= -900.0f);
    std::cout << "[PASS] test_thorax_phantom" << std::endl;
}

void run_phantom_tests() {
    test_water_phantom();
    test_thorax_phantom();
    std::cout << "[ALL PASS] Phantom verification suite completed." << std::endl;
}

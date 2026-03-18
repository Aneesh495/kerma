#include "kerma/beam_geometry.hpp"
#include <cassert>
#include <cmath>
#include <iostream>

void test_source_positions() {
    kerma::BeamParameters b;
    b.sad_mm = 1000.0f;
    b.isocenter_mm = {0.0f, 0.0f, 0.0f};

    // Gantry 0 deg: source at (0, 0, -1000)
    b.gantry_angle_deg = 0.0f;
    kerma::Vec3 pos0 = kerma::compute_source_world_position(b);
    assert(std::abs(pos0.x) < 1.0e-2f);
    assert(std::abs(pos0.y) < 1.0e-2f);
    assert(std::abs(pos0.z - (-1000.0f)) < 1.0e-2f);

    // Gantry 90 deg: source at (-1000, 0, 0)
    b.gantry_angle_deg = 90.0f;
    kerma::Vec3 pos90 = kerma::compute_source_world_position(b);
    assert(std::abs(pos90.x - (-1000.0f)) < 1.0e-2f);
    assert(std::abs(pos90.z) < 1.0e-2f);

    std::cout << "[PASS] test_source_positions" << std::endl;
}

void test_aperture_clipping() {
    kerma::BeamParameters b;
    b.sad_mm = 1000.0f;
    b.gantry_angle_deg = 0.0f;
    b.jaw_x1_mm = -50.0f;
    b.jaw_x2_mm =  50.0f;
    b.jaw_y1_mm = -50.0f;
    b.jaw_y2_mm =  50.0f;

    // Origin (0,0,0) is at isocenter inside field
    assert(kerma::is_point_in_field_aperture({0.0f, 0.0f, 0.0f}, b));

    // Point far out at x = 200 mm is outside field
    assert(!kerma::is_point_in_field_aperture({200.0f, 0.0f, 0.0f}, b));

    std::cout << "[PASS] test_aperture_clipping" << std::endl;
}

void run_geometry_tests() {
    test_source_positions();
    test_aperture_clipping();
    std::cout << "[ALL PASS] Geometry verification suite completed." << std::endl;
}

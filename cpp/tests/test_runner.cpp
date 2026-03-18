#include <iostream>

void run_phantom_tests();
void run_geometry_tests();
void run_analytical_dose_tests();
void run_gamma_tests();

int main() {
    std::cout << "=================================================================\n";
    std::cout << "KERMA C++20 COMPREHENSIVE VERIFICATION TEST HARNESS\n";
    std::cout << "=================================================================\n";

    std::cout << "[SUITE 1/4] Running Phantom Synthesis Tests...\n";
    run_phantom_tests();

    std::cout << "\n[SUITE 2/4] Running IEC Beam Geometry Tests...\n";
    run_geometry_tests();

    std::cout << "\n[SUITE 3/4] Running Analytical Dosimetry Models...\n";
    run_analytical_dose_tests();

    std::cout << "\n[SUITE 4/4] Running AAPM TG-218 3D Gamma Index Tests...\n";
    run_gamma_tests();

    std::cout << "=================================================================\n";
    std::cout << "ALL C++20 VERIFICATION TESTS PASSED SUCCESSFULLY (0 FAILURES)\n";
    std::cout << "=================================================================\n";

    return 0;
}

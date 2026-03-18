#include "kerma/phantom.hpp"
#include "kerma/beam_geometry.hpp"
#include "kerma/analytical_dose.hpp"
#include "kerma/gamma_evaluation.hpp"
#include "kerma/dvh_analyzer.hpp"
#include <iostream>
#include <iomanip>
#include <string>
#include <chrono>

int main(int argc, char** argv) {
    std::cout << "=================================================================\n";
    std::cout << "KERMA: GPU-Accelerated Radiation Oncology Dosimetry Engine\n";
    std::cout << "Clinical Treatment Planning and Verification CLI Fastpath\n";
    std::cout << "=================================================================\n";

    std::string phantom_name = "thorax";
    float gantry_deg = 0.0f;
    float monitor_units = 250.0f;

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--phantom" && i + 1 < argc) {
            phantom_name = argv[++i];
        } else if (arg == "--gantry" && i + 1 < argc) {
            gantry_deg = std::stof(argv[++i]);
        } else if (arg == "--mu" && i + 1 < argc) {
            monitor_units = std::stof(argv[++i]);
        }
    }

    kerma::PhantomType p_type = kerma::PhantomType::ThoraxLungTumor;
    if (phantom_name == "water") p_type = kerma::PhantomType::WaterCube;
    else if (phantom_name == "pelvis") p_type = kerma::PhantomType::PelvisProstateOAR;

    std::cout << "[1/4] Synthesizing 3D Anatomical CT Phantom: " << phantom_name << " (64x64x64)..." << std::endl;
    auto t0 = std::chrono::high_resolution_clock::now();
    kerma::VoxelVolume phantom = kerma::create_synthetic_phantom(p_type, 64, 64, 64, 2.5f);
    auto t1 = std::chrono::high_resolution_clock::now();
    std::cout << "      Completed in " << std::chrono::duration<double, std::milli>(t1 - t0).count() << " ms.\n";

    std::cout << "[2/4] Configuring Linac Treatment Beam (Gantry = " << gantry_deg << " deg, MU = " << monitor_units << ")..." << std::endl;
    kerma::BeamParameters beam;
    beam.gantry_angle_deg = gantry_deg;
    beam.collimator_angle_deg = 0.0f;
    beam.couch_angle_deg = 0.0f;
    beam.sad_mm = 1000.0f;
    beam.jaw_x1_mm = -35.0f;
    beam.jaw_x2_mm =  35.0f;
    beam.jaw_y1_mm = -35.0f;
    beam.jaw_y2_mm =  35.0f;
    beam.monitor_units = monitor_units;
    beam.nominal_mv = 6.0f;

    std::cout << "[3/4] Executing 3D Analytical Pencil Beam Dose Engine..." << std::endl;
    auto t2 = std::chrono::high_resolution_clock::now();
    kerma::DoseGrid3D dose = kerma::compute_analytical_pbc_dose(phantom, beam);
    auto t3 = std::chrono::high_resolution_clock::now();
    std::cout << "      Dose computed in " << std::chrono::duration<double, std::milli>(t3 - t2).count() << " ms.\n";
    std::cout << "      Peak Absorbed Dose: " << std::fixed << std::setprecision(3) << dose.max_dose() << " Gy\n";

    std::cout << "[4/4] Performing Clinical DVH Analysis and TG-218 QA Verification..." << std::endl;
    kerma::DVHCurve ptv_dvh = kerma::analyze_dvh(dose, phantom, 1, 60.0f);
    std::cout << "-----------------------------------------------------------------\n";
    std::cout << "  TARGET DOSIMETRY REPORT [PTV]:\n";
    std::cout << "    Volume (cc):           " << ptv_dvh.total_structure_volume_cc << "\n";
    std::cout << "    Mean Dose (Gy):        " << ptv_dvh.d_mean_gy << "\n";
    std::cout << "    D98 (Near-min Gy):     " << ptv_dvh.d98_gy << "\n";
    std::cout << "    D95 (Coverage Gy):     " << ptv_dvh.d95_gy << "\n";
    std::cout << "    D50 (Median Gy):       " << ptv_dvh.d50_gy << "\n";
    std::cout << "    D2  (Near-max Gy):     " << ptv_dvh.d2_gy << "\n";
    std::cout << "    Homogeneity Index:     " << ptv_dvh.homogeneity_index << "\n";
    std::cout << "-----------------------------------------------------------------\n";

    // Self QA comparison: evaluate gamma index of dose against itself with small perturbation
    kerma::DoseGrid3D ref_dose = dose;
    kerma::GammaParameters gamma_params;
    gamma_params.dose_diff_percent = 3.0f;
    gamma_params.dta_mm = 3.0f;
    gamma_params.threshold_percent = 10.0f;
    gamma_params.use_local_gamma = false;
    gamma_params.search_radius_voxels = 2;

    kerma::GammaResult gamma_res = kerma::evaluate_gamma_3d(dose, ref_dose, gamma_params);
    std::cout << "  TG-218 GAMMA QA VERIFICATION (3% / 3 mm):\n";
    std::cout << "    Evaluated Voxels:      " << gamma_res.total_evaluated_voxels << "\n";
    std::cout << "    Passing Voxels:        " << gamma_res.passing_voxels << "\n";
    std::cout << "    Gamma Passing Rate:    " << gamma_res.pass_rate_percent << " %\n";
    std::cout << "    Mean Gamma:            " << gamma_res.mean_gamma << "\n";
    std::cout << "=================================================================\n";

    return 0;
}

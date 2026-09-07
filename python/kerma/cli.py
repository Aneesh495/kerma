"""Command line interface for Kerma Python digital twin simulation."""

import argparse
import sys
from .phantom import build_synthetic_phantom, PhantomKind
from .plan import LinacBeam, TreatmentPlan
from .dose import calculate_pencil_beam_dose, calculate_plan_dose
from .dvh import calculate_dvh
from .gamma import evaluate_gamma_3d


def main():
    parser = argparse.ArgumentParser(description="Kerma Radiation Oncology Simulation Engine")
    parser.add_argument("--phantom", choices=["water", "thorax", "pelvis"], default="thorax", help="Phantom geometry")
    parser.add_argument("--mu", type=float, default=200.0, help="Monitor units per beam")
    parser.add_argument("--gantry", type=float, default=0.0, help="Gantry angle (degrees)")
    parser.add_argument("--gamma-dta", type=float, default=3.0, help="Gamma DTA criterion (mm)")
    parser.add_argument("--gamma-dd", type=float, default=3.0, help="Gamma dose difference criterion (%%)")

    args = parser.parse_args()

    kind_map = {
        "water": PhantomKind.WATER_CUBE,
        "thorax": PhantomKind.THORAX_LUNG,
        "pelvis": PhantomKind.PELVIS_PROSTATE
    }
    p_kind = kind_map[args.phantom]

    print("=================================================================")
    print("KERMA: Python Digital-Twin Radiation Oncology Planning Suite")
    print("=================================================================")
    print(f"Synthesizing {args.phantom.upper()} anatomical CT phantom (32x32x32)...")
    phantom = build_synthetic_phantom(kind=p_kind, shape=(32, 32, 32), spacing_mm=(5.0, 5.0, 5.0))

    beam = LinacBeam(
        name="Anterior_Beam",
        gantry_angle_deg=args.gantry,
        monitor_units=args.mu,
        jaw_x1_mm=-35.0,
        jaw_x2_mm=35.0,
        jaw_y1_mm=-35.0,
        jaw_y2_mm=35.0
    )

    print(f"Calculating 3D dose grid (MU = {args.mu}, Gantry = {args.gantry} deg)...")
    dose = calculate_pencil_beam_dose(phantom, beam)
    print(f"  Maximum Absorbed Dose: {dose.max_dose:.3f} Gy")
    print(f"  Mean Absorbed Dose:    {dose.mean_dose:.3f} Gy")

    print("\nClinical Target Dosimetry [PTV]:")
    ptv_dvh = calculate_dvh(dose, phantom, "PTV")
    print(f"  Volume (cc):           {ptv_dvh.volume_cc:.2f}")
    print(f"  D98 (Near-min Gy):     {ptv_dvh.d98_gy:.2f}")
    print(f"  D95 (Coverage Gy):     {ptv_dvh.d95_gy:.2f}")
    print(f"  D50 (Median Gy):       {ptv_dvh.d50_gy:.2f}")
    print(f"  D2  (Near-max Gy):     {ptv_dvh.d2_gy:.2f}")
    print(f"  Homogeneity Index:     {ptv_dvh.homogeneity_index:.3f}")

    print(f"\nAAPM TG-218 Quality Assurance Verification ({args.gamma_dd}% / {args.gamma_dta} mm):")
    gamma_res = evaluate_gamma_3d(
        evaluated=dose,
        reference=dose,
        dose_diff_percent=args.gamma_dd,
        dta_mm=args.gamma_dta,
        search_radius_voxels=2
    )
    print(f"  Evaluated Voxels:      {gamma_res.total_evaluated_voxels}")
    print(f"  Passing Rate:          {gamma_res.pass_rate_percent:.1f} %")
    print("=================================================================")


if __name__ == "__main__":
    main()

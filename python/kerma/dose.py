"""3D Dose volume computation and analytical pencil beam verification engine."""

from __future__ import annotations
from dataclasses import dataclass
import numpy as np
from .phantom import SyntheticPhantom
from .plan import LinacBeam, TreatmentPlan


@dataclass
class DoseVolume3D:
    dimensions: tuple[int, int, int]
    spacing_mm: tuple[float, float, float]
    origin_mm: tuple[float, float, float]
    dose_gy: np.ndarray

    @property
    def max_dose(self) -> float:
        return float(np.max(self.dose_gy))

    @property
    def mean_dose(self) -> float:
        return float(np.mean(self.dose_gy))


def calculate_pencil_beam_dose(phantom: SyntheticPhantom, beam: LinacBeam) -> DoseVolume3D:
    nx, ny, nz = phantom.dimensions
    dx, dy, dz = phantom.spacing_mm
    ox, oy, oz = phantom.origin_mm

    x = ox + (np.arange(nx) + 0.5) * dx
    y = oy + (np.arange(ny) + 0.5) * dy
    z = oz + (np.arange(nz) + 0.5) * dz

    X, Y, Z = np.meshgrid(x, y, z, indexing="ij")

    g_rad = np.radians(beam.gantry_angle_deg)
    cos_g = np.cos(g_rad)
    sin_g = np.sin(g_rad)

    # Source position in world coordinates
    src_x = -beam.sad_mm * sin_g
    src_y = 0.0
    src_z = -beam.sad_mm * cos_g

    # Distance to source
    dist_sq = (X - src_x)**2 + (Y - src_y)**2 + (Z - src_z)**2
    dist = np.sqrt(np.maximum(1.0, dist_sq))

    # Transform to BEV coordinates at isocenter
    dx_iso = X - beam.isocenter_mm[0]
    dy_iso = Y - beam.isocenter_mm[1]
    dz_iso = Z - beam.isocenter_mm[2]

    bev_x =  dx_iso * cos_g - dz_iso * sin_g
    bev_y =  dy_iso
    bev_z =  dx_iso * sin_g + dz_iso * cos_g

    z_from_src = beam.sad_mm + bev_z
    scale = np.where(z_from_src > 10.0, beam.sad_mm / np.maximum(10.0, z_from_src), 0.0)

    u_proj = bev_x * scale
    v_proj = bev_y * scale

    in_field = (
        (u_proj >= beam.jaw_x1_mm) & (u_proj <= beam.jaw_x2_mm) &
        (v_proj >= beam.jaw_y1_mm) & (v_proj <= beam.jaw_y2_mm)
    )

    inv_sq = (beam.sad_mm / dist)**2

    # Depth dose in phantom
    d_max_mm = 15.0
    mu_eff = 0.0045 # mm^-1

    geom_depth = np.maximum(0.0, bev_z + 75.0)
    d_eff = geom_depth * phantom.rho_e

    pdd = np.where(
        d_eff <= d_max_mm,
        0.45 + 0.55 * np.sqrt(np.maximum(0.0, d_eff / d_max_mm)),
        np.exp(-mu_eff * (d_eff - d_max_mm))
    )

    in_body = phantom.mass_density > 0.05
    fluence_factor = np.where(in_field, 1.0, 0.005) # 0.5% transmission under jaws

    dose_gy = np.where(
        in_body,
        pdd * inv_sq * fluence_factor * (beam.monitor_units * 0.01),
        0.0
    ).astype(np.float32)

    return DoseVolume3D(
        dimensions=phantom.dimensions,
        spacing_mm=phantom.spacing_mm,
        origin_mm=phantom.origin_mm,
        dose_gy=dose_gy
    )


def calculate_plan_dose(phantom: SyntheticPhantom, plan: TreatmentPlan) -> DoseVolume3D:
    total_dose = np.zeros(phantom.dimensions, dtype=np.float32)
    for beam in plan.beams:
        b_dose = calculate_pencil_beam_dose(phantom, beam)
        total_dose += b_dose.dose_gy

    return DoseVolume3D(
        dimensions=phantom.dimensions,
        spacing_mm=phantom.spacing_mm,
        origin_mm=phantom.origin_mm,
        dose_gy=total_dose
    )

"""AAPM TG-218 3D Gamma Index evaluation engine."""

from __future__ import annotations
from dataclasses import dataclass
import numpy as np
from .dose import DoseVolume3D


@dataclass
class GammaResult:
    pass_rate_percent: float
    mean_gamma: float
    max_gamma: float
    total_evaluated_voxels: int
    passing_voxels: int
    gamma_map: np.ndarray


def evaluate_gamma_3d(
    evaluated: DoseVolume3D,
    reference: DoseVolume3D,
    dose_diff_percent: float = 3.0,
    dta_mm: float = 3.0,
    threshold_percent: float = 10.0,
    use_local_gamma: bool = False,
    search_radius_voxels: int = 3
) -> GammaResult:
    d_eval = evaluated.dose_gy
    d_ref  = reference.dose_gy

    max_ref = float(np.max(d_ref))
    dose_threshold = (threshold_percent * 0.01) * max_ref

    valid_mask = d_ref >= dose_threshold
    evaluated_count = int(np.count_nonzero(valid_mask))

    if evaluated_count == 0:
        return GammaResult(
            pass_rate_percent=100.0,
            mean_gamma=0.0,
            max_gamma=0.0,
            total_evaluated_voxels=0,
            passing_voxels=0,
            gamma_map=np.zeros_like(d_ref)
        )

    gamma_map = np.zeros_like(d_ref)
    inv_dta_sq = 1.0 / (dta_mm * dta_mm)

    global_delta_d = (dose_diff_percent * 0.01) * max_ref
    global_inv_dd_sq = 1.0 / (global_delta_d * global_delta_d)

    dx, dy, dz = reference.spacing_mm
    r = search_radius_voxels

    # Evaluate neighborhood search across valid voxels
    nx, ny, nz = reference.dimensions
    passing_count = 0
    gamma_values = []

    # Fast evaluation loop over valid voxels
    valid_indices = np.argwhere(valid_mask)
    for idx_tuple in valid_indices:
        ix, iy, iz = idx_tuple
        d_m = d_ref[ix, iy, iz]

        inv_dd_sq = global_inv_dd_sq
        if use_local_gamma:
            local_delta_d = (dose_diff_percent * 0.01) * max(0.01, d_m)
            inv_dd_sq = 1.0 / (local_delta_d * local_delta_d)

        min_g_sq = 1.0e6

        x_min, x_max = max(0, ix - r), min(nx - 1, ix + r)
        y_min, y_max = max(0, iy - r), min(ny - 1, iy + r)
        z_min, z_max = max(0, iz - r), min(nz - 1, iz + r)

        for cz in range(z_min, z_max + 1):
            dz_mm = (cz - iz) * dz
            dz2 = dz_mm * dz_mm
            for cy in range(y_min, y_max + 1):
                dy_mm = (cy - iy) * dy
                dy2 = dy_mm * dy_mm
                for cx in range(x_min, x_max + 1):
                    dx_mm = (cx - ix) * dx
                    dist_sq = dx_mm * dx_mm + dy2 + dz2
                    dist_term = dist_sq * inv_dta_sq
                    if dist_term >= min_g_sq:
                        continue

                    d_c = d_eval[cx, cy, cz]
                    diff = d_m - d_c
                    dose_term = (diff * diff) * inv_dd_sq
                    g_sq = dist_term + dose_term
                    if g_sq < min_g_sq:
                        min_g_sq = g_sq

        g_val = float(np.sqrt(min_g_sq))
        gamma_map[ix, iy, iz] = g_val
        gamma_values.append(g_val)
        if g_val <= 1.0:
            passing_count += 1

    pass_rate = (float(passing_count) / float(evaluated_count)) * 100.0
    mean_g = float(np.mean(gamma_values)) if gamma_values else 0.0
    max_g  = float(np.max(gamma_values)) if gamma_values else 0.0

    return GammaResult(
        pass_rate_percent=pass_rate,
        mean_gamma=mean_g,
        max_gamma=max_g,
        total_evaluated_voxels=evaluated_count,
        passing_voxels=passing_count,
        gamma_map=gamma_map
    )

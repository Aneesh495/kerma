"""Dose-Volume Histogram (DVH) computation and clinical metric extraction."""

from __future__ import annotations
from dataclasses import dataclass
import numpy as np
from .phantom import SyntheticPhantom
from .dose import DoseVolume3D


@dataclass
class DVHReport:
    structure_name: str
    volume_cc: float
    mean_dose_gy: float
    min_dose_gy: float
    max_dose_gy: float
    d98_gy: float  # Near-min dose
    d95_gy: float  # Target coverage
    d50_gy: float  # Median dose
    d2_gy: float   # Near-max dose (hot spot)
    v20_pct: float # Volume >= 20 Gy
    v50_pct: float # Volume >= 50 Gy
    homogeneity_index: float
    dose_bins_gy: np.ndarray
    cumulative_vol_pct: np.ndarray


def calculate_dvh(
    dose: DoseVolume3D,
    phantom: SyntheticPhantom,
    structure_name: str,
    max_dose_scale_gy: float = 80.0,
    num_bins: int = 1000
) -> DVHReport:
    mask = phantom.roi_masks.get(structure_name)
    voxel_vol_cc = (phantom.spacing_mm[0] * phantom.spacing_mm[1] * phantom.spacing_mm[2]) * 1.0e-3

    if mask is None or np.count_nonzero(mask) == 0:
        empty_bins = np.linspace(0.0, max_dose_scale_gy, num_bins, dtype=np.float32)
        return DVHReport(
            structure_name=structure_name,
            volume_cc=0.0,
            mean_dose_gy=0.0,
            min_dose_gy=0.0,
            max_dose_gy=0.0,
            d98_gy=0.0,
            d95_gy=0.0,
            d50_gy=0.0,
            d2_gy=0.0,
            v20_pct=0.0,
            v50_pct=0.0,
            homogeneity_index=0.0,
            dose_bins_gy=empty_bins,
            cumulative_vol_pct=np.zeros(num_bins, dtype=np.float32)
        )

    structure_doses = dose.dose_gy[mask]
    total_voxels = structure_doses.size
    total_vol_cc = float(total_voxels * voxel_vol_cc)

    mean_d = float(np.mean(structure_doses))
    min_d  = float(np.min(structure_doses))
    max_d  = float(np.max(structure_doses))

    bins = np.linspace(0.0, max_dose_scale_gy, num_bins, dtype=np.float32)
    counts, _ = np.histogram(structure_doses, bins=np.append(bins, bins[-1] + (bins[1] - bins[0])))

    # Cumulative reverse sum: V(>= D)
    reverse_counts = np.cumsum(counts[::-1])[::-1]
    cum_vol_pct = (reverse_counts / float(total_voxels)) * 100.0

    def dose_at_volume(target_pct: float) -> float:
        for i in range(num_bins - 1):
            v1, v2 = cum_vol_pct[i], cum_vol_pct[i + 1]
            if v1 >= target_pct >= v2:
                d1, d2 = bins[i], bins[i + 1]
                t = (v1 - target_pct) / max(1.0e-5, (v1 - v2))
                return float(d1 + t * (d2 - d1))
        return 0.0 if cum_vol_pct[0] < target_pct else max_d

    def volume_at_dose(target_gy: float) -> float:
        if target_gy <= bins[0]: return 100.0
        if target_gy >= bins[-1]: return 0.0
        idx = int(np.searchsorted(bins, target_gy))
        return float(cum_vol_pct[min(idx, num_bins - 1)])

    d98 = dose_at_volume(98.0)
    d95 = dose_at_volume(95.0)
    d50 = dose_at_volume(50.0)
    d2  = dose_at_volume(2.0)

    v20 = volume_at_dose(20.0)
    v50 = volume_at_dose(50.0)

    hi = (d2 - d98) / max(0.01, d50)

    return DVHReport(
        structure_name=structure_name,
        volume_cc=total_vol_cc,
        mean_dose_gy=mean_d,
        min_dose_gy=min_d,
        max_dose_gy=max_d,
        d98_gy=d98,
        d95_gy=d95,
        d50_gy=d50,
        d2_gy=d2,
        v20_pct=v20,
        v50_pct=v50,
        homogeneity_index=hi,
        dose_bins_gy=bins,
        cumulative_vol_pct=cum_vol_pct
    )

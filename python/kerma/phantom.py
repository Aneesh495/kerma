"""Synthetic anatomical CT phantom generator for dosimetry benchmarking.

Generates calibrated 3D voxel matrices representing standard clinical cases:
- Homogeneous water tank QA phantom
- Anthropomorphic thorax phantom with lungs, spine, and solitary pulmonary nodule
- Pelvic phantom with prostate PTV, rectum, bladder, and bilateral femoral heads
"""

from __future__ import annotations
import enum
from dataclasses import dataclass
import numpy as np


class PhantomKind(enum.Enum):
    WATER_CUBE = "water"
    THORAX_LUNG = "thorax"
    PELVIS_PROSTATE = "pelvis"


@dataclass
class SyntheticPhantom:
    kind: PhantomKind
    dimensions: tuple[int, int, int]
    spacing_mm: tuple[float, float, float]
    origin_mm: tuple[float, float, float]
    hu_data: np.ndarray        # Hounsfield Units (-1000 to +3000)
    mass_density: np.ndarray   # g / cm^3
    rho_e: np.ndarray          # Electron density relative to water
    roi_masks: dict[str, np.ndarray] # ROI name to boolean mask


def build_synthetic_phantom(
    kind: PhantomKind = PhantomKind.THORAX_LUNG,
    shape: tuple[int, int, int] = (64, 64, 64),
    spacing_mm: tuple[float, float, float] = (2.5, 2.5, 2.5)
) -> SyntheticPhantom:
    nx, ny, nz = shape
    dx, dy, dz = spacing_mm
    origin = (
        -0.5 * nx * dx,
        -0.5 * ny * dy,
        -0.5 * nz * dz
    )

    x_coords = origin[0] + (np.arange(nx) + 0.5) * dx
    y_coords = origin[1] + (np.arange(ny) + 0.5) * dy
    z_coords = origin[2] + (np.arange(nz) + 0.5) * dz

    X, Y, Z = np.meshgrid(x_coords, y_coords, z_coords, indexing="ij")

    hu = np.full(shape, -1000.0, dtype=np.float32)
    rho = np.full(shape, 0.0012, dtype=np.float32)
    rho_e = np.full(shape, 0.001, dtype=np.float32)
    rois: dict[str, np.ndarray] = {}

    if kind == PhantomKind.WATER_CUBE:
        in_water = (np.abs(X) <= 75.0) & (np.abs(Y) <= 75.0) & (np.abs(Z) <= 75.0)
        hu[in_water] = 0.0
        rho[in_water] = 1.000
        rho_e[in_water] = 1.000

        in_ptv = (np.abs(X) <= 20.0) & (np.abs(Y) <= 20.0) & (np.abs(Z) <= 20.0)
        rois["BODY"] = in_water
        rois["PTV"] = in_ptv

    elif kind == PhantomKind.THORAX_LUNG:
        r_body = np.sqrt(X**2 + Y**2)
        in_body = (r_body <= 70.0) & (np.abs(Z) <= 60.0)
        hu[in_body] = 40.0
        rho[in_body] = 1.05
        rho_e[in_body] = 1.04

        r_lung_l = np.sqrt((X - 32.0)**2 + (Y - 5.0)**2)
        r_lung_r = np.sqrt((X + 32.0)**2 + (Y - 5.0)**2)
        in_lungs = in_body & ((r_lung_l <= 25.0) | (r_lung_r <= 25.0))
        hu[in_lungs] = -700.0
        rho[in_lungs] = 0.26
        rho_e[in_lungs] = 0.26

        r_spine = np.sqrt(X**2 + (Y + 45.0)**2)
        in_spine = in_body & (r_spine <= 12.0)
        hu[in_spine] = 800.0
        rho[in_spine] = 1.45
        rho_e[in_spine] = 1.38

        r_tumor = np.sqrt((X - 32.0)**2 + (Y - 5.0)**2 + Z**2)
        in_tumor = in_body & (r_tumor <= 14.0)
        hu[in_tumor] = 50.0
        rho[in_tumor] = 1.06
        rho_e[in_tumor] = 1.05

        rois["BODY"] = in_body
        rois["LUNGS"] = in_lungs & (~in_tumor)
        rois["SPINE"] = in_spine
        rois["PTV"] = in_tumor

    else:
        # Pelvic phantom
        oval = (X**2) / (75.0**2) + (Y**2) / (60.0**2)
        in_body = (oval <= 1.0) & (np.abs(Z) <= 65.0)
        hu[in_body] = 35.0
        rho[in_body] = 1.03
        rho_e[in_body] = 1.02

        r_pros = np.sqrt(X**2 + Y**2 + Z**2)
        in_pros = in_body & (r_pros <= 18.0)
        hu[in_pros] = 45.0
        rho[in_pros] = 1.05
        rho_e[in_pros] = 1.04

        r_rect = np.sqrt(X**2 + (Y + 26.0)**2)
        in_rect = in_body & (r_rect <= 11.0)
        hu[in_rect] = 20.0
        rho[in_rect] = 1.01
        rho_e[in_rect] = 1.00

        r_blad = np.sqrt(X**2 + (Y - 28.0)**2 + Z**2)
        in_blad = in_body & (r_blad <= 20.0)
        hu[in_blad] = 5.0
        rho[in_blad] = 1.00
        rho_e[in_blad] = 1.00

        rois["BODY"] = in_body
        rois["PTV"] = in_pros
        rois["RECTUM"] = in_rect
        rois["BLADDER"] = in_blad

    return SyntheticPhantom(
        kind=kind,
        dimensions=shape,
        spacing_mm=spacing_mm,
        origin_mm=origin,
        hu_data=hu,
        mass_density=rho,
        rho_e=rho_e,
        roi_masks=rois
    )

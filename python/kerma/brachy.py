"""AAPM TG-43 Brachytherapy Dose Rate and Dwell-Time Lattice Superposition."""

from __future__ import annotations
from dataclasses import dataclass
from typing import List, Tuple
import math
import numpy as np
from .phantom import SyntheticPhantom
from .dose import DoseVolume3D


@dataclass
class BrachySeed:
    position_mm: Tuple[float, float, float] = (0.0, 0.0, 0.0)
    orientation: Tuple[float, float, float] = (0.0, 0.0, 1.0)
    air_kerma_strength_u: float = 40700.0
    active_length_mm: float = 3.6
    dose_rate_constant: float = 1.109


def geometry_factor_line(r_cm: np.ndarray, theta_rad: np.ndarray, active_length_cm: float) -> np.ndarray:
    """Computes AAPM TG-43 line-source geometry factor G_L(r, theta) in cm^-2."""
    r_safe = np.maximum(r_cm, 1e-4)
    if active_length_cm <= 1e-4:
        return 1.0 / (r_safe * r_safe)

    sin_theta = np.sin(theta_rad)
    cos_theta = np.cos(theta_rad)
    half_l = 0.5 * active_length_cm

    # Along capsule axis sin(theta) -> 0
    on_axis = np.abs(sin_theta) < 1e-4
    g_axis = 1.0 / np.maximum(r_safe * r_safe - half_l * half_l, 1e-5)

    # Off-axis line source angle beta
    beta1 = np.arctan2(r_safe * sin_theta, r_safe * cos_theta - half_l)
    beta2 = np.arctan2(r_safe * sin_theta, r_safe * cos_theta + half_l)
    beta = np.abs(beta1 - beta2)
    g_off = beta / (active_length_cm * r_safe * np.where(on_axis, 1.0, sin_theta))

    return np.where(on_axis, g_axis, g_off)


def radial_dose_function(r_cm: np.ndarray) -> np.ndarray:
    """Computes polynomial radial dose function g_L(r) for HDR Ir-192."""
    r = np.clip(r_cm, 0.1, 15.0)
    a0, a1, a2, a3, a4 = 1.0084, -0.0072, -0.0003, -0.0001, 0.00001
    return a0 + a1 * r + a2 * (r ** 2) + a3 * (r ** 3) + a4 * (r ** 4)


def anisotropy_function(theta_rad: np.ndarray) -> np.ndarray:
    """Computes symmetric 2D anisotropy function F(r, theta) for Ir-192 capsule."""
    deg = np.degrees(theta_rad)
    deg = np.where(deg > 180.0, 360.0 - deg, deg)
    deg = np.where(deg > 90.0, 180.0 - deg, deg)

    f = np.ones_like(deg, dtype=np.float32)
    f = np.where(deg < 60.0, 0.98, f)
    f = np.where(deg < 30.0, 0.90, f)
    f = np.where(deg < 15.0, 0.78, f)
    f = np.where(deg < 5.0, 0.63, f)
    return f


def calculate_brachy_lattice_dose(
    phantom: SyntheticPhantom,
    seeds: List[BrachySeed],
    dwell_time_seconds: float,
) -> DoseVolume3D:
    """Computes 3D brachytherapy dose distribution in Gray across phantom coordinates."""
    nz, ny, nx = phantom.hu_data.shape
    dx, dy, dz = phantom.spacing_mm
    ox, oy, oz = phantom.origin_mm

    z_coords = oz + np.arange(nz, dtype=np.float32) * dz
    y_coords = oy + np.arange(ny, dtype=np.float32) * dy
    x_coords = ox + np.arange(nx, dtype=np.float32) * dx
    zz, yy, xx = np.meshgrid(z_coords, y_coords, x_coords, indexing="ij")

    total_rate_cgy_h = np.zeros_like(xx, dtype=np.float32)
    g_ref_cache = {}

    for seed in seeds:
        rx_cm = (xx - seed.position_mm[0]) * 0.1
        ry_cm = (yy - seed.position_mm[1]) * 0.1
        rz_cm = (zz - seed.position_mm[2]) * 0.1

        r_cm = np.sqrt(rx_cm ** 2 + ry_cm ** 2 + rz_cm ** 2)
        r_cm = np.maximum(r_cm, 0.05)

        ori = np.array(seed.orientation, dtype=np.float32)
        ori = ori / max(float(np.linalg.norm(ori)), 1e-6)
        dot = (rx_cm * ori[0] + ry_cm * ori[1] + rz_cm * ori[2]) / r_cm
        theta_rad = np.arccos(np.clip(dot, -1.0, 1.0))

        l_cm = seed.active_length_mm * 0.1
        if l_cm not in g_ref_cache:
            g_ref_cache[l_cm] = float(
                geometry_factor_line(np.array([1.0]), np.array([0.5 * math.pi]), l_cm)[0]
            )
        g_ref = max(g_ref_cache[l_cm], 1e-5)

        g_ratio = geometry_factor_line(r_cm, theta_rad, l_cm) / g_ref
        g_r = radial_dose_function(r_cm)
        f_ang = anisotropy_function(theta_rad)

        rate = seed.air_kerma_strength_u * seed.dose_rate_constant * g_ratio * g_r * f_ang
        total_rate_cgy_h += rate

    dwell_hours = dwell_time_seconds / 3600.0
    dose_gy = (total_rate_cgy_h * dwell_hours * 0.01).astype(np.float32)

    return DoseVolume3D(
        dimensions=phantom.dimensions,
        spacing_mm=phantom.spacing_mm,
        origin_mm=phantom.origin_mm,
        dose_gy=dose_gy,
    )

"""Radiobiological Modeling: BED, EQD2, gEUD, LKB-NTCP, and Tumor Control Probability."""

from __future__ import annotations
import math
import numpy as np


def compute_bed(dose_gy: np.ndarray, num_fractions: int, alpha_beta_gy: float) -> np.ndarray:
    """Computes Biologically Effective Dose (BED) using the Linear-Quadratic model."""
    n = max(float(num_fractions), 1.0)
    d_per_fx = dose_gy / n
    return dose_gy * (1.0 + d_per_fx / max(alpha_beta_gy, 1e-4))


def compute_eqd2(dose_gy: np.ndarray, num_fractions: int, alpha_beta_gy: float) -> np.ndarray:
    """Computes Equivalent Dose in 2 Gy Fractions (EQD2)."""
    bed = compute_bed(dose_gy, num_fractions, alpha_beta_gy)
    return bed / (1.0 + 2.0 / max(alpha_beta_gy, 1e-4))


def compute_generalized_eud(structure_doses_gy: np.ndarray, parameter_a: float) -> float:
    """Computes Niemierko's Generalized Equivalent Uniform Dose (gEUD).

    For tumors, a < 0 (e.g. -10) emphasizes cold spots.
    For serial organs (cord), a >> 1 (e.g. +10 to +20) approaches D_max.
    For parallel organs (lung, parotid), a ~ 1 approaches D_mean.
    """
    if structure_doses_gy.size == 0:
        return 0.0
    doses = np.maximum(structure_doses_gy.astype(np.float64), 1e-5)
    if abs(parameter_a) < 1e-3:
        # Limit as a -> 0 is geometric mean
        return float(np.exp(np.mean(np.log(doses))))
    mean_pow = np.mean(np.power(doses, parameter_a))
    return float(np.power(mean_pow, 1.0 / parameter_a))


def compute_lkb_ntcp(
    structure_doses_gy: np.ndarray,
    td50_gy: float,
    slope_m: float,
    volume_param_n: float,
) -> float:
    """Computes Lyman-Kutcher-Burman Normal Tissue Complication Probability (NTCP)."""
    if structure_doses_gy.size == 0:
        return 0.0
    a = 1.0 / max(volume_param_n, 1e-4)
    eud = compute_generalized_eud(structure_doses_gy, a)
    t = (eud - td50_gy) / max(slope_m * td50_gy, 1e-5)
    # Standard normal CDF: 0.5 * (1 + erf(t / sqrt(2)))
    return float(0.5 * (1.0 + math.erf(t / math.sqrt(2.0))))


def compute_poisson_tcp(
    structure_doses_gy: np.ndarray,
    tcd50_gy: float,
    gamma50: float,
) -> float:
    """Computes logistic/Poisson-based Tumor Control Probability (TCP)."""
    if structure_doses_gy.size == 0:
        return 0.0
    eud = compute_generalized_eud(structure_doses_gy, -10.0)
    if eud <= 0.0:
        return 0.0
    exponent = 4.0 * gamma50 * (1.0 - eud / max(tcd50_gy, 1e-4))
    exponent = max(-50.0, min(50.0, exponent))
    return float(1.0 / (1.0 + math.exp(exponent)))

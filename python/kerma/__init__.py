"""Kerma: High-Performance GPU-Accelerated Radiation Oncology Dosimetry Engine.

Provides physical CT calibration, Linac beam modeling, Collapsed Cone Convolution,
Pencil Beam superposition, 4D breathing motion deformation, and AAPM TG-218 QA analysis.
"""

from .phantom import SyntheticPhantom, PhantomKind
from .plan import LinacBeam, TreatmentPlan
from .dose import DoseVolume3D, calculate_pencil_beam_dose
from .dvh import calculate_dvh, DVHReport
from .gamma import evaluate_gamma_3d, GammaResult
from .brachy import BrachySeed, calculate_brachy_lattice_dose
from .radiobiology import (
    compute_bed,
    compute_eqd2,
    compute_generalized_eud,
    compute_lkb_ntcp,
    compute_poisson_tcp,
)

__version__ = "0.1.0"
__all__ = [
    "SyntheticPhantom",
    "PhantomKind",
    "LinacBeam",
    "TreatmentPlan",
    "DoseVolume3D",
    "calculate_pencil_beam_dose",
    "calculate_dvh",
    "DVHReport",
    "evaluate_gamma_3d",
    "GammaResult",
    "BrachySeed",
    "calculate_brachy_lattice_dose",
    "compute_bed",
    "compute_eqd2",
    "compute_generalized_eud",
    "compute_lkb_ntcp",
    "compute_poisson_tcp",
]

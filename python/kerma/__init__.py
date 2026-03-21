"""Kerma: High-Performance GPU-Accelerated Radiation Oncology Dosimetry Engine.

Provides physical CT calibration, Linac beam modeling, Collapsed Cone Convolution,
Pencil Beam superposition, 4D breathing motion deformation, and AAPM TG-218 QA analysis.
"""

from .phantom import SyntheticPhantom, PhantomKind
from .plan import LinacBeam, TreatmentPlan
from .dose import DoseVolume3D, calculate_pencil_beam_dose
from .dvh import calculate_dvh, DVHReport
from .gamma import evaluate_gamma_3d, GammaResult

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
]

"""Radiation therapy treatment plan and Linac beam configuration data structures."""

from __future__ import annotations
from dataclasses import dataclass, field
import numpy as np


@dataclass
class LinacBeam:
    name: str = "Beam_1"
    gantry_angle_deg: float = 0.0
    collimator_angle_deg: float = 0.0
    couch_angle_deg: float = 0.0
    sad_mm: float = 1000.0
    isocenter_mm: tuple[float, float, float] = (0.0, 0.0, 0.0)
    jaw_x1_mm: float = -40.0
    jaw_x2_mm: float =  40.0
    jaw_y1_mm: float = -40.0
    jaw_y2_mm: float =  40.0
    monitor_units: float = 100.0
    nominal_mv: float = 6.0
    mlc_leaf_pairs: list[tuple[float, float]] = field(default_factory=list)


@dataclass
class TreatmentPlan:
    patient_id: str = "ANON_001"
    prescription_dose_gy: float = 60.0
    fractions: int = 30
    beams: list[LinacBeam] = field(default_factory=list)

    @property
    def total_monitor_units(self) -> float:
        return sum(b.monitor_units for b in self.beams)

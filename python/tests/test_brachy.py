"""Unit tests for AAPM TG-43 Brachytherapy Formalism."""

import math
import unittest
import numpy as np
from kerma.phantom import build_synthetic_phantom, PhantomKind
from kerma.brachy import (
    BrachySeed,
    geometry_factor_line,
    radial_dose_function,
    anisotropy_function,
    calculate_brachy_lattice_dose,
)


class TestBrachytherapyTG43(unittest.TestCase):
    def test_radial_dose_and_anisotropy_reference(self):
        # At r = 1.0 cm, g_L(1.0) should be near unity
        g1 = radial_dose_function(np.array([1.0], dtype=np.float32))[0]
        self.assertAlmostEqual(float(g1), 1.0, delta=0.01)

        # Transverse axis (theta = 90 deg) anisotropy must be 1.0
        f_trans = anisotropy_function(np.array([0.5 * math.pi], dtype=np.float32))[0]
        self.assertAlmostEqual(float(f_trans), 1.0, delta=1e-4)

        # Longitudinal weld shadow attenuation (< 0.70)
        f_long = anisotropy_function(np.array([0.0], dtype=np.float32))[0]
        self.assertLess(float(f_long), 0.70)

    def test_geometry_factor_on_and_off_axis(self):
        g_trans = geometry_factor_line(np.array([1.0]), np.array([0.5 * math.pi]), 0.36)[0]
        self.assertGreater(float(g_trans), 0.95)
        self.assertLess(float(g_trans), 1.05)

        g_axis = geometry_factor_line(np.array([1.0]), np.array([0.0]), 0.36)[0]
        # 1 / (1^2 - 0.18^2) ~ 1.033
        self.assertAlmostEqual(float(g_axis), 1.0 / (1.0 - 0.18 ** 2), delta=0.01)

    def test_brachy_lattice_dose_distribution(self):
        phantom = build_synthetic_phantom(PhantomKind.WATER_CUBE, shape=(9, 9, 9), spacing_mm=(5.0, 5.0, 5.0))
        seed = BrachySeed(position_mm=(0.0, 0.0, 0.0), air_kerma_strength_u=40700.0)
        dose = calculate_brachy_lattice_dose(phantom, [seed], dwell_time_seconds=60.0)
        self.assertGreater(dose.max_dose, 1.0)
        # Inverse square falloff: center must exceed corners
        center_val = float(dose.dose_gy[4, 4, 4])
        corner_val = float(dose.dose_gy[0, 0, 0])
        self.assertGreater(center_val, corner_val)


if __name__ == "__main__":
    unittest.main()

"""Unit tests for Dose-Volume Histogram calculation and edge cases."""

import unittest
import numpy as np
from kerma.phantom import build_synthetic_phantom, PhantomKind
from kerma.dose import DoseVolume3D
from kerma.dvh import calculate_dvh


class TestDVHAnalytics(unittest.TestCase):
    def test_uniform_dose_dvh(self):
        phantom = build_synthetic_phantom(
            PhantomKind.WATER_CUBE, shape=(10, 10, 10), spacing_mm=(2.0, 2.0, 2.0)
        )
        uniform_grid = np.full((10, 10, 10), 60.0, dtype=np.float32)
        dose = DoseVolume3D(
            dimensions=phantom.dimensions,
            spacing_mm=phantom.spacing_mm,
            origin_mm=phantom.origin_mm,
            dose_gy=uniform_grid,
        )
        dvh = calculate_dvh(dose, phantom, "PTV", max_dose_scale_gy=80.0)
        self.assertGreater(dvh.volume_cc, 0.0)
        self.assertAlmostEqual(dvh.mean_dose_gy, 60.0, delta=0.1)
        self.assertAlmostEqual(dvh.d95_gy, 60.0, delta=0.2)
        self.assertAlmostEqual(dvh.d50_gy, 60.0, delta=0.2)
        self.assertAlmostEqual(dvh.d2_gy, 60.0, delta=0.2)
        self.assertAlmostEqual(dvh.v20_pct, 100.0, delta=0.1)
        self.assertLess(dvh.homogeneity_index, 0.05)

    def test_missing_structure_returns_zero(self):
        phantom = build_synthetic_phantom(PhantomKind.WATER_CUBE, shape=(8, 8, 8))
        dose = DoseVolume3D(
            dimensions=phantom.dimensions,
            spacing_mm=phantom.spacing_mm,
            origin_mm=phantom.origin_mm,
            dose_gy=np.zeros((8, 8, 8), dtype=np.float32),
        )
        dvh = calculate_dvh(dose, phantom, "NONEXISTENT_ROI")
        self.assertEqual(dvh.volume_cc, 0.0)
        self.assertEqual(dvh.mean_dose_gy, 0.0)


if __name__ == "__main__":
    unittest.main()

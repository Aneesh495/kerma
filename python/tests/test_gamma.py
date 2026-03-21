"""Tests for 3D Gamma index evaluation."""

import unittest
import numpy as np
from kerma.dose import DoseVolume3D
from kerma.gamma import evaluate_gamma_3d


class TestGammaEvaluation(unittest.TestCase):
    def test_identical_dose_pass(self):
        shape = (10, 10, 10)
        d_arr = np.full(shape, 2.0, dtype=np.float32)
        dose = DoseVolume3D(dimensions=shape, spacing_mm=(2.5, 2.5, 2.5), origin_mm=(0.0, 0.0, 0.0), dose_gy=d_arr)

        res = evaluate_gamma_3d(dose, dose, dose_diff_percent=3.0, dta_mm=3.0, search_radius_voxels=1)
        self.assertAlmostEqual(res.pass_rate_percent, 100.0, places=1)
        self.assertAlmostEqual(res.mean_gamma, 0.0, places=2)

    def test_failing_dose(self):
        shape = (10, 10, 10)
        d_arr = np.full(shape, 2.0, dtype=np.float32)
        d_bad = d_arr * 1.25 # 25% discrepancy
        ref = DoseVolume3D(dimensions=shape, spacing_mm=(2.5, 2.5, 2.5), origin_mm=(0.0, 0.0, 0.0), dose_gy=d_arr)
        eval_d = DoseVolume3D(dimensions=shape, spacing_mm=(2.5, 2.5, 2.5), origin_mm=(0.0, 0.0, 0.0), dose_gy=d_bad)

        res = evaluate_gamma_3d(eval_d, ref, dose_diff_percent=3.0, dta_mm=3.0, search_radius_voxels=1)
        self.assertLess(res.pass_rate_percent, 10.0)


if __name__ == "__main__":
    unittest.main()

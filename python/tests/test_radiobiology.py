"""Unit tests for Radiobiology BED, EQD2, gEUD, LKB-NTCP, and TCP models."""

import unittest
import numpy as np
from kerma.radiobiology import (
    compute_bed,
    compute_eqd2,
    compute_generalized_eud,
    compute_lkb_ntcp,
    compute_poisson_tcp,
)


class TestRadiobiology(unittest.TestCase):
    def test_bed_and_eqd2_standard_fractionation(self):
        # 60 Gy in 30 fractions (2 Gy/fx) with alpha/beta = 10 Gy:
        # EQD2 must equal exactly 60.0 Gy; BED = 60 * (1 + 2/10) = 72.0 Gy
        d = np.array([60.0], dtype=np.float32)
        bed = float(compute_bed(d, num_fractions=30, alpha_beta_gy=10.0)[0])
        eqd2 = float(compute_eqd2(d, num_fractions=30, alpha_beta_gy=10.0)[0])
        self.assertAlmostEqual(bed, 72.0, delta=1e-4)
        self.assertAlmostEqual(eqd2, 60.0, delta=1e-4)

    def test_sbrt_hypofractionation_bed(self):
        # 54 Gy in 3 fractions (18 Gy/fx) with alpha/beta = 10 Gy:
        # BED = 54 * (1 + 18/10) = 54 * 2.8 = 151.2 Gy
        d = np.array([54.0], dtype=np.float32)
        bed = float(compute_bed(d, num_fractions=3, alpha_beta_gy=10.0)[0])
        self.assertAlmostEqual(bed, 151.2, delta=1e-3)

    def test_geud_serial_vs_parallel(self):
        doses = np.array([10.0, 20.0, 60.0], dtype=np.float32)
        eud_parallel = compute_generalized_eud(doses, parameter_a=1.0)
        eud_serial = compute_generalized_eud(doses, parameter_a=20.0)
        eud_tumor = compute_generalized_eud(doses, parameter_a=-10.0)

        self.assertAlmostEqual(eud_parallel, 30.0, delta=1e-3)
        self.assertGreater(eud_serial, 50.0)
        self.assertLess(eud_tumor, 15.0)

    def test_ntcp_and_tcp_monotonicity(self):
        # At TD50, LKB NTCP should be exactly 0.50
        uniform_td50 = np.full(100, 45.0, dtype=np.float32)
        ntcp_50 = compute_lkb_ntcp(uniform_td50, td50_gy=45.0, slope_m=0.15, volume_param_n=0.5)
        self.assertAlmostEqual(ntcp_50, 0.5, delta=1e-4)

        # At TCD50, TCP should be 0.50; higher dose gives higher TCP
        uniform_tcd50 = np.full(100, 65.0, dtype=np.float32)
        uniform_high = np.full(100, 95.0, dtype=np.float32)
        tcp_50 = compute_poisson_tcp(uniform_tcd50, tcd50_gy=65.0, gamma50=2.0)
        tcp_high = compute_poisson_tcp(uniform_high, tcd50_gy=65.0, gamma50=2.0)
        self.assertAlmostEqual(tcp_50, 0.5, delta=1e-4)
        self.assertGreater(tcp_high, 0.9)


if __name__ == "__main__":
    unittest.main()

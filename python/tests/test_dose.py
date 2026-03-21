"""Tests for dose calculation and DVH extraction."""

import unittest
from kerma.phantom import build_synthetic_phantom, PhantomKind
from kerma.plan import LinacBeam
from kerma.dose import calculate_pencil_beam_dose
from kerma.dvh import calculate_dvh


class TestDoseAndDVH(unittest.TestCase):
    def test_pbc_dose_and_dvh(self):
        phantom = build_synthetic_phantom(PhantomKind.WATER_CUBE, shape=(16, 16, 16), spacing_mm=(5.0, 5.0, 5.0))
        beam = LinacBeam(monitor_units=150.0, jaw_x1_mm=-25.0, jaw_x2_mm=25.0, jaw_y1_mm=-25.0, jaw_y2_mm=25.0)

        dose = calculate_pencil_beam_dose(phantom, beam)
        self.assertGreater(dose.max_dose, 0.5)

        dvh = calculate_dvh(dose, phantom, "PTV")
        self.assertGreater(dvh.volume_cc, 0.0)
        self.assertGreater(dvh.d50_gy, 0.0)


if __name__ == "__main__":
    unittest.main()

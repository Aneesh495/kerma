"""Tests for synthetic phantom generation."""

import unittest
import numpy as np
from kerma.phantom import build_synthetic_phantom, PhantomKind


class TestSyntheticPhantom(unittest.TestCase):
    def test_water_phantom(self):
        p = build_synthetic_phantom(PhantomKind.WATER_CUBE, shape=(16, 16, 16), spacing_mm=(5.0, 5.0, 5.0))
        self.assertEqual(p.dimensions, (16, 16, 16))
        self.assertIn("BODY", p.roi_masks)
        self.assertIn("PTV", p.roi_masks)

        # Center should be water
        cx, cy, cz = 8, 8, 8
        self.assertAlmostEqual(float(p.hu_data[cx, cy, cz]), 0.0, places=1)
        self.assertAlmostEqual(float(p.mass_density[cx, cy, cz]), 1.0, places=2)

    def test_thorax_phantom(self):
        p = build_synthetic_phantom(PhantomKind.THORAX_LUNG, shape=(20, 20, 20), spacing_mm=(5.0, 5.0, 5.0))
        self.assertIn("LUNGS", p.roi_masks)
        self.assertIn("SPINE", p.roi_masks)
        self.assertIn("PTV", p.roi_masks)


if __name__ == "__main__":
    unittest.main()

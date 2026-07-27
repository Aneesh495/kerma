"""Structural and physical integrity tests for clinical datasets in data/."""

import json
import os
import unittest


REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


class TestClinicalDatasets(unittest.TestCase):
    def test_phantom_metadata_schemas(self):
        phantom_dir = os.path.join(REPO_ROOT, "data", "phantoms")
        expected_files = ["water_cube_meta.json", "thorax_meta.json", "pelvis_meta.json"]
        for fname in expected_files:
            fpath = os.path.join(phantom_dir, fname)
            self.assertTrue(os.path.exists(fpath), f"Missing {fpath}")
            with open(fpath, "r", encoding="utf-8") as f:
                meta = json.load(f)
            self.assertIn("phantom_id", meta)
            self.assertEqual(len(meta["dimensions"]), 3)
            self.assertEqual(len(meta["voxel_spacing_mm"]), 3)
            self.assertGreater(len(meta["structures"]), 0)

    def test_bremsstrahlung_spectra_normalization(self):
        spectra_dir = os.path.join(REPO_ROOT, "data", "spectra")
        for fname in os.listdir(spectra_dir):
            if not fname.endswith(".dat"):
                continue
            fpath = os.path.join(spectra_dir, fname)
            energies = []
            weights = []
            with open(fpath, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    parts = line.split()
                    energies.append(float(parts[0]))
                    weights.append(float(parts[1]))
            self.assertGreater(len(energies), 10, f"Too few bins in {fname}")
            self.assertEqual(energies, sorted(energies), f"Non-monotonic energy in {fname}")
            total_w = sum(weights)
            self.assertAlmostEqual(total_w, 1.0, delta=0.05, msg=f"Unnormalized spectrum in {fname}: {total_w}")

    def test_cccs_kernels_and_tg43_tables(self):
        kernels_dir = os.path.join(REPO_ROOT, "data", "kernels")
        for fname in ["cccs_kernel_6mv.dat", "cccs_kernel_10mv.dat", "cccs_kernel_15mv.dat"]:
            fpath = os.path.join(kernels_dir, fname)
            angles = []
            primaries = []
            with open(fpath, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    parts = line.split()
                    angles.append(float(parts[0]))
                    primaries.append(float(parts[1]))
            self.assertEqual(angles[0], 0.0)
            self.assertEqual(angles[-1], 180.0)
            # Forward scattering dominance: A(0 deg) > A(90 deg)
            self.assertGreater(primaries[0], primaries[9])

        tg43_path = os.path.join(kernels_dir, "tg43_ir192_seed.dat")
        self.assertTrue(os.path.exists(tg43_path))


if __name__ == "__main__":
    unittest.main()

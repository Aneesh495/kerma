#!/usr/bin/env python3
"""Benchmark 3D Gamma Index evaluation scaling across search radii."""

import time
import sys
import numpy as np
from pathlib import Path

repo_root = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(repo_root / "python"))

from kerma.dose import DoseVolume3D
from kerma.gamma import evaluate_gamma_3d


def main():
    shape = (20, 20, 20)
    d1 = np.full(shape, 2.0, dtype=np.float32)
    d2 = d1 * 1.01 # 1% perturbation
    dose1 = DoseVolume3D(shape, (2.5, 2.5, 2.5), (0.0, 0.0, 0.0), d1)
    dose2 = DoseVolume3D(shape, (2.5, 2.5, 2.5), (0.0, 0.0, 0.0), d2)

    radii = [1, 2, 3]
    print("=================================================================")
    print("KERMA 3D GAMMA INDEX SEARCH SCALING BENCHMARK")
    print("=================================================================")

    for r in radii:
        window_size = (2 * r + 1) ** 3
        start = time.perf_counter()
        res = evaluate_gamma_3d(dose1, dose2, search_radius_voxels=r)
        elapsed = time.perf_counter() - start
        print(f"  Search Radius r = {r} ({window_size:>4} stencil pts): {elapsed * 1000.0:>6.2f} ms | Pass Rate: {res.pass_rate_percent:.1f}%")

    print("=================================================================")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Benchmark CPU dose calculation throughput across resolution scales."""

import time
import sys
from pathlib import Path

# Add python directory to path
repo_root = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(repo_root / "python"))

from kerma.phantom import build_synthetic_phantom, PhantomKind
from kerma.plan import LinacBeam
from kerma.dose import calculate_pencil_beam_dose


def main():
    resolutions = [(16, 16, 16), (32, 32, 32), (64, 64, 64)]
    print("=================================================================")
    print("KERMA CPU DOSE CALCULATION BENCHMARK")
    print("=================================================================")

    for res in resolutions:
        total_voxels = res[0] * res[1] * res[2]
        phantom = build_synthetic_phantom(PhantomKind.THORAX_LUNG, shape=res, spacing_mm=(2.5, 2.5, 2.5))
        beam = LinacBeam(monitor_units=200.0)

        start = time.perf_counter()
        dose = calculate_pencil_beam_dose(phantom, beam)
        elapsed = time.perf_counter() - start

        throughput = float(total_voxels) / (elapsed * 1.0e6) # MVoxels / s
        print(f"  Resolution {res[0]}x{res[1]}x{res[2]:<3} ({total_voxels:>7} voxels): {elapsed * 1000.0:>7.2f} ms ({throughput:>5.2f} MVox/s)")

    print("=================================================================")


if __name__ == "__main__":
    main()

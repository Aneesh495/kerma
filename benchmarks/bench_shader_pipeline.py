#!/usr/bin/env python3
"""Benchmark GLSL shader compilation throughput to SPIR-V."""

import time
import subprocess
from pathlib import Path


def main():
    repo_root = Path(__file__).resolve().parent.parent
    shaders = list((repo_root / "shaders").rglob("*.comp")) + \
              list((repo_root / "shaders").rglob("*.vert")) + \
              list((repo_root / "shaders").rglob("*.frag"))

    print(f"Benchmarking SPIR-V compilation for {len(shaders)} stage shaders...")
    start_time = time.perf_counter()

    for s in shaders:
        spv = s.with_suffix(s.suffix + ".bench.spv")
        res = subprocess.run(["glslangValidator", "-V", str(s), "-o", str(spv)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if res.returncode != 0:
            print(f"Error compiling {s.name}")
        if spv.exists():
            spv.unlink()

    elapsed = time.perf_counter() - start_time
    print(f"Completed in {elapsed:.3f} s ({elapsed / len(shaders) * 1000.0:.2f} ms per shader).")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Shader validation and line count accounting tool for Kerma.

Invokes glslangValidator across all stage shaders (.comp, .vert, .frag)
compiling each to SPIR-V, verifying syntax, type safety, and memory layouts.
Also calculates precise physical line counts across all GLSL source files.
"""

import subprocess
import sys
from pathlib import Path


def count_lines(file_path: Path) -> int:
    try:
        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            return sum(1 for _ in f)
    except Exception:
        return 0


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    shaders_dir = repo_root / "shaders"

    if not shaders_dir.exists():
        print(f"Error: shaders directory not found at {shaders_dir}", file=sys.stderr)
        return 1

    glsl_files = sorted(shaders_dir.rglob("*.*"))
    target_stages = {".comp", ".vert", ".frag"}
    all_glsl_exts = {".comp", ".vert", ".frag", ".glsl"}

    total_lines = 0
    stage_files = []
    lines_by_module = {}

    for path in glsl_files:
        ext = path.suffix.lower()
        if ext in all_glsl_exts:
            lines = count_lines(path)
            total_lines += lines
            module = path.parent.name
            lines_by_module[module] = lines_by_module.get(module, 0) + lines
            if ext in target_stages:
                stage_files.append(path)

    print("=================================================================")
    print("KERMA GLSL SHADER PIPELINE VALIDATION & ACCOUNTING")
    print("=================================================================")
    for mod, count in sorted(lines_by_module.items()):
        print(f"  Module [shaders/{mod:<12}]: {count:>6} lines")
    print("-----------------------------------------------------------------")
    print(f"  TOTAL GLSL SOURCE LINES:     {total_lines:>6} lines")
    print(f"  STAGE SHADERS TO VALIDATE:   {len(stage_files):>6} files")
    print("=================================================================")

    # Test glslangValidator availability
    try:
        subprocess.run(["glslangValidator", "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    except Exception as exc:
        print(f"Warning: glslangValidator not functional ({exc}). Skipping SPIR-V compilation.", file=sys.stderr)
        return 0

    failures = 0
    for stage_path in stage_files:
        rel = stage_path.relative_to(repo_root)
        out_spv = stage_path.with_suffix(stage_path.suffix + ".spv")
        res = subprocess.run(
            ["glslangValidator", "-V", str(stage_path), "-o", str(out_spv)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        if res.returncode != 0:
            print(f"[FAIL] {rel}:")
            print(res.stdout)
            print(res.stderr, file=sys.stderr)
            failures += 1
        else:
            # Clean up generated spv
            if out_spv.exists():
                out_spv.unlink()
            print(f"[PASS] {rel}")

    if failures > 0:
        print(f"\nValidation failed with {failures} error(s).", file=sys.stderr)
        return 1

    print(f"\nAll {len(stage_files)} stage shaders successfully validated and compiled to SPIR-V.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

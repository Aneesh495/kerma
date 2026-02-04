#!/usr/bin/env python3
"""Kerma source code typography auditor.

Verifies that no unicode em dashes (U+2014) or en dashes (U+2013) are present
in source files, headers, shaders, documentation, or configuration files.
"""

import sys
from pathlib import Path

FORBIDDEN = ("\u2014", "\u2013")
SKIP_EXTENSIONS = {".png", ".jpg", ".spv", ".o", ".a", ".dylib", ".so"}
SKIP_DIRS = {".git", "build", "bin", "__pycache__"}


def scan_file(path: Path) -> list[str]:
    violations = []
    try:
        content = path.read_text(encoding="utf-8", errors="replace")
    except Exception as err:
        return [f"{path}: read error: {err}"]

    for line_idx, line in enumerate(content.splitlines(), start=1):
        for sym in FORBIDDEN:
            if sym in line:
                violations.append(
                    f"{path}:{line_idx}: forbidden dash character found in line -> {line.strip()}"
                )
    return violations


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    all_violations = []
    file_count = 0

    for item in root.rglob("*"):
        if item.is_file():
            if any(part in SKIP_DIRS for part in item.parts):
                continue
            if item.suffix.lower() in SKIP_EXTENSIONS:
                continue
            if item.name == "check_typography.py":
                continue
            violations = scan_file(item)
            if violations:
                all_violations.extend(violations)
            file_count += 1

    if all_violations:
        print(f"FAILED: Found {len(all_violations)} typography issues across {file_count} files:", file=sys.stderr)
        for v in all_violations:
            print(f"  {v}", file=sys.stderr)
        return 1

    print(f"PASSED: Audited {file_count} files. Zero forbidden dash characters detected.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

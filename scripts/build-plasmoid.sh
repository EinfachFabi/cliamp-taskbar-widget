#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$PROJECT_ROOT/dist"

mkdir -p "$DIST_DIR"

# Sync latest cliamp-kde-ctl into both plasmoid bundles
cp "$PROJECT_ROOT/bin/cliamp-kde-ctl" "$PROJECT_ROOT/plasmoid/contents/scripts/cliamp-kde-ctl"
cp "$PROJECT_ROOT/bin/cliamp-kde-ctl" "$PROJECT_ROOT/plasmoid-plasma5/contents/scripts/cliamp-kde-ctl"
chmod +x "$PROJECT_ROOT/plasmoid/contents/scripts/cliamp-kde-ctl"
chmod +x "$PROJECT_ROOT/plasmoid-plasma5/contents/scripts/cliamp-kde-ctl"

python3 - "$PROJECT_ROOT" "$DIST_DIR" << 'EOF'
import os
import sys
import zipfile

project_root = sys.argv[1]
dist_dir = sys.argv[2]

def make_plasmoid(src_dir: str, out_file: str) -> None:
    with zipfile.ZipFile(out_file, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, _, files in os.walk(src_dir):
            for f in sorted(files):
                full_path = os.path.join(root, f)
                rel_path = os.path.relpath(full_path, src_dir)
                zf.write(full_path, rel_path)

p6_out = os.path.join(dist_dir, "cliamp-kde-plasma6.plasmoid")
p5_out = os.path.join(dist_dir, "cliamp-kde-plasma5.plasmoid")

make_plasmoid(os.path.join(project_root, "plasmoid"), p6_out)
make_plasmoid(os.path.join(project_root, "plasmoid-plasma5"), p5_out)

print(f"Built: {p6_out}")
print(f"Built: {p5_out}")
EOF

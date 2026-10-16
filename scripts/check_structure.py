#!/usr/bin/env python3
"""Check repository metadata and relative documentation links without external dependencies."""

import json
import plistlib
import re
from pathlib import Path
from urllib.parse import unquote

root = Path(__file__).resolve().parent.parent
required = [
    "AGENTS.md", "README.md", "CONTRIBUTING.md", "SPEC.md", "SCOPE.md", "ROADMAP.md",
    "docs/README.md", "docs/logic/timing.md", "docs/development.md",
    "testing/MANUAL TO-DO/README.md", "testing/MANUAL TO-DO/timer.md",
    ".github/pull_request_template.md", ".github/workflows/ci.yml", "project.yml",
]
errors = [f"Missing {path}" for path in required if not (root / path).is_file()]
json.loads((root / ".swift-format").read_text())
info = plistlib.loads((root / "App/Info.plist").read_bytes())
entitlements = plistlib.loads((root / "App/Dayleft.entitlements").read_bytes())
if info.get("LSUIElement") is not True:
    errors.append("Menu-bar app must set LSUIElement=true")
if entitlements != {"com.apple.security.app-sandbox": True}:
    errors.append("Scaffold must remain sandboxed without provider entitlements")
for path in [root / name for name in required if name.endswith(".md")]:
    if not path.exists():
        continue
    for link in re.findall(r"\]\(([^)]+)\)", path.read_text()):
        link = link.strip("<>")
        if "://" in link or link.startswith(("#", "mailto:")):
            continue
        destination = unquote(link.split("#", 1)[0])
        if destination and not (path.parent / destination).exists():
            errors.append(f"Broken documentation link in {path.relative_to(root)}: {link}")
if errors:
    raise SystemExit("\n".join(errors))
print("Repository structure, property lists, and documentation links passed.")

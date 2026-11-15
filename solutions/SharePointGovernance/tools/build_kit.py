"""Build the governance deployment kit: one versioned zip with everything
DEPLOY-AND-TEST.md refers to, plus a manifest of SHA-256 checksums.

The kit holds the importable solution (built here, so the two always match),
the runbook, provisioning script, list schema and CSV templates, dashboard
definition, SAM policy sheet, guides, diagrams, the Claude skill and the
tools themselves, so a second operator can deploy from the kit alone.

Usage: python solutions/SharePointGovernance/tools/build_kit.py [--out DIR]
"""
import hashlib
import json
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPO = ROOT.parent.parent
OUT = Path(sys.argv[sys.argv.index("--out") + 1]).resolve() if "--out" in sys.argv else ROOT / "dist"
CONFIG = json.loads((ROOT / "solution-config.json").read_text())
VERSION = CONFIG["version"]
VTAG = VERSION.replace(".", "_")

# Folders and files copied into the kit, relative to the solution folder.
INCLUDE = ["README.md", "DEPLOY-AND-TEST.md", "SAM-POLICIES.md", "solution-config.json",
           "powerautomate", "runbooks", "provisioning", "sharepoint", "diagrams", "skills", "tools"]
EXTRA = {"docs/POWER-PLATFORM-DEPLOYMENT.md": REPO / "solutions" / "POWER-PLATFORM-DEPLOYMENT.md"}


def files():
    for name in INCLUDE:
        path = ROOT / name
        for f in ([path] if path.is_file() else sorted(path.rglob("*"))):
            if f.is_file() and "__pycache__" not in f.parts:
                yield f.relative_to(ROOT).as_posix(), f
    for arc, f in EXTRA.items():
        yield arc, f


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    subprocess.run([sys.executable, str(ROOT / "tools" / "build_solution.py"), "--out", str(OUT)], check=True)
    solution = OUT / f"SharePointGovernance_{VTAG}.zip"
    commit = subprocess.run(["git", "-C", str(REPO), "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip() or "unknown"

    entries = list(files()) + [(f"solution/{solution.name}", solution)]
    manifest = {"kit": "SharePoint governance deployment kit", "version": VERSION, "sourceCommit": commit,
                "files": {arc: hashlib.sha256(f.read_bytes()).hexdigest() for arc, f in entries}}
    kit = OUT / f"SharePointGovernance-DeploymentKit_{VTAG}.zip"
    top = f"SharePointGovernance-DeploymentKit_{VTAG}"
    with zipfile.ZipFile(kit, "w", zipfile.ZIP_DEFLATED) as z:
        for arc, f in entries:
            z.write(f, f"{top}/{arc}")
        z.writestr(f"{top}/MANIFEST.json", json.dumps(manifest, indent=2) + "\n")
    print(f"Built {kit.relative_to(Path.cwd()) if kit.is_relative_to(Path.cwd()) else kit} "
          f"({len(entries)} files, source {commit[:7]})")


if __name__ == "__main__":
    main()

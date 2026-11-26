"""Cross-solution checks for every solutions/*/solution-config.json.

Solutions built by build_solution.py share one publisher prefix and one ID namespace, so two
solutions imported into the same environment can collide without either build noticing:

  * an environment variable name used by two solutions becomes one shared setting
    (spg_<Name>), so setting it for one solution silently changes the other
  * a flow file name used by two solutions gives both flows the same workflow ID, so
    importing one overwrites the other
  * two solutions without distinct connectionReferenceTag values share connection references

Usage: python solutions/SharePointGovernance/tools/check_solutions.py
"""
import json
import sys
from collections import defaultdict
from pathlib import Path

SOLUTIONS = Path(__file__).resolve().parents[2]


def main():
    env, flows, tags, errors = defaultdict(list), defaultdict(list), defaultdict(list), []
    configs = sorted(SOLUTIONS.glob("*/solution-config.json"))
    for path in configs:
        cfg = json.loads(path.read_text())
        name, prefix = cfg["uniqueName"], cfg["publisher"]["prefix"]
        for var in cfg["environmentVariables"]:
            env[f"{prefix}_{var}"].append(name)
        for flow in (path.parent / "powerautomate" / "flows").glob("*.json"):
            flows[flow.stem].append(name)
        tags[(prefix, cfg.get("connectionReferenceTag", ""))].append(name)
    for var, owners in sorted(env.items()):
        if len(owners) > 1:
            errors.append(f"environment variable {var} is defined by {', '.join(owners)}: rename it in all but one")
    for stem, owners in sorted(flows.items()):
        if len(owners) > 1:
            errors.append(f"flow file name {stem} is used by {', '.join(owners)}: both get the same workflow ID")
    for (prefix, tag), owners in sorted(tags.items()):
        if len(owners) > 1:
            errors.append(f"connectionReferenceTag '{tag}' ({prefix}) is shared by {', '.join(owners)}")
    for e in errors:
        print("ERROR", e)
    print(f"{len(configs)} solutions, {len(env)} environment variables, {len(flows)} flows: "
          + ("ok" if not errors else f"{len(errors)} problem(s)"))
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()

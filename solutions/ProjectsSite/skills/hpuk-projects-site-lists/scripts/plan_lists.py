"""Preview which lists Provision-ProjectLists.ps1 will create, and check the schemas first.

Runs offline (no SharePoint connection). Use it before every provisioning run so the person
running it can confirm the plan, and in CI (--check) so a schema the script can't apply never
reaches the skill.

Usage:
  python scripts/plan_lists.py --sets pmo,board         # plan for those sets
  python scripts/plan_lists.py --sets all
  python scripts/plan_lists.py --check                  # validate every set; exit 1 on problems
"""
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
CATALOGUE = json.loads((HERE / "schemas" / "catalogue.json").read_text())
SUPPORTED = {"Text", "Note", "Number", "DateTime", "Boolean", "Choice", "Person", "Lookup", "URL"}
TEMPLATES = {"GenericList", "DocumentLibrary", "Events"}


def list_url(l):
    """Same rule as Provision-ProjectLists.ps1: the schema's url, else derived from the title."""
    if l.get("url"):
        return l["url"]
    slug = re.sub(r"[^A-Za-z0-9_]", "", l["listTitle"])
    return slug if l.get("template") == "DocumentLibrary" else f"Lists/{slug}"


def load(keys):
    return {k: json.loads((HERE / "schemas" / CATALOGUE["sets"][k]["schema"]).read_text())["lists"] for k in keys}


def problems(sets):
    errs, titles, urls = [], {}, {}
    for key, lists in sets.items():
        seen_lists = []
        for l in lists:
            t = l["listTitle"]
            if t in titles:
                errs.append(f"{key}: list '{t}' is also in set '{titles[t]}'")
            titles[t] = key
            u = list_url(l).lower()
            if u in urls:
                errs.append(f"{key}: '{t}' URL {u} clashes with '{urls[u]}'")
            urls[u] = t
            if l.get("template", "GenericList") not in TEMPLATES:
                errs.append(f"{key}/{t}: unsupported template {l.get('template')}")
            names = [f["internalName"] for f in l["fields"]]
            for n in {n for n in names if names.count(n) > 1}:
                errs.append(f"{key}/{t}: column {n} defined twice")
            for f in l["fields"]:
                where = f"{key}/{t}.{f['internalName']}"
                if f["type"] not in SUPPORTED:
                    errs.append(f"{where}: type {f['type']} not supported by the script")
                if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]{0,31}", f["internalName"]):
                    errs.append(f"{where}: internal name must be letters/digits/_ and at most 32 characters")
                if f["type"] == "Choice":
                    if not f.get("choices"):
                        errs.append(f"{where}: choice column without choices")
                    elif f.get("default") not in (None, "") and str(f["default"]) not in f["choices"]:
                        errs.append(f"{where}: default '{f['default']}' is not one of its choices")
                if f["type"] == "Lookup" and f.get("lookupList") not in seen_lists:
                    errs.append(f"{where}: looks up '{f.get('lookupList')}', which must come earlier in the same set")
            seen_lists.append(t)
    return errs


def main():
    args = sys.argv[1:]
    check = "--check" in args
    if check:
        keys = list(CATALOGUE["sets"])
    else:
        raw = args[args.index("--sets") + 1] if "--sets" in args else "all"
        keys = list(CATALOGUE["sets"]) if raw == "all" else [k.strip() for k in raw.split(",")]
        unknown = [k for k in keys if k not in CATALOGUE["sets"]]
        if unknown:
            sys.exit(f"unknown set(s) {unknown}; choose from {list(CATALOGUE['sets'])} or all")
    sets = load(keys)
    errs = problems(sets)

    total_new = 0
    for key, lists in sets.items():
        spec = CATALOGUE["sets"][key]
        print(f"\n[{key}] {spec['title']}: {len(lists)} lists")
        for l in lists:
            mode = "check only (must already exist)" if l.get("existingOnly") else "create if missing"
            total_new += 0 if l.get("existingOnly") else 1
            print(f"  - {l['listTitle']:<34} {l.get('template', 'GenericList'):<15} {len(l['fields']):>2} columns  {list_url(l):<36} {mode}")
    print(f"\n{total_new} lists to create if missing, across {len(keys)} set(s). Existing lists and columns are never changed or deleted.")

    warned = False
    for o in CATALOGUE["overlaps"]:
        chosen = [f"{o['lists'][k]} ({k})" for k in keys if k in o["lists"]]
        if len(set(chosen)) > 1:
            if not warned:
                print("\nOverlaps: these lists do the same job; agree which is the master before creating more than one:")
                warned = True
            print(f"  - {o['role']}: " + ", ".join(chosen))

    if errs:
        print("\nSchema problems (fix the source schema, rebuild the skill, then run again):")
        for e in errs:
            print("  ERROR", e)
        sys.exit(1)
    print("\nSchemas: ok")


if __name__ == "__main__":
    main()

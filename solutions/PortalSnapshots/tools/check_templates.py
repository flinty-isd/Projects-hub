"""Check the portal templates against the snapshot flows.

Each flow fills in the empty snapshot block of one template and writes it as a page. This checks
that every page a flow writes has a template in templates/, that each template has the empty
block exactly once (a saved snapshot uploaded as a template has none, and the flow would stop),
and that templates leave room under SharePoint's 10 MB limit for HTML pages.

Usage: python solutions/PortalSnapshots/tools/check_templates.py
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MARKER = '<script id="embedded-snapshot" type="application/json">null</script>'
LIMIT = 10_000_000


def walk(actions):
    for name, a in actions.items():
        yield name, a
        yield from walk(a.get("actions", {}))
        yield from walk(a.get("else", {}).get("actions", {}))


def main():
    errors, pages = [], set()
    for path in sorted((ROOT / "powerautomate" / "flows").glob("*.json")):
        flow = json.loads(path.read_text())
        for name, a in walk(flow["actions"]):
            params = a.get("inputs", {}).get("parameters", {}) if isinstance(a.get("inputs"), dict) else {}
            if params and a["inputs"].get("host", {}).get("operationId") == "CreateFile":
                pages.add(params["name"])
                print(f"{path.name}: writes {params['name']}")
    for page in sorted(pages):
        t = ROOT / "templates" / page
        if not t.exists():
            errors.append(f"{page}: no template in templates/")
            continue
        text = t.read_text(encoding="utf-8")
        n = text.count(MARKER)
        if n != 1:
            errors.append(f"{page}: empty snapshot block found {n} times, expected 1")
        if len(text.encode()) > LIMIT // 2:
            errors.append(f"{page}: template is {len(text.encode()) // 1024} KB, leaving too little room for data under 10 MB")
    for e in errors:
        print("ERROR", e)
    print(f"{len(pages)} templates: " + ("ok" if not errors else f"{len(errors)} problem(s)"))
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()

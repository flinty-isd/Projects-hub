"""Generate SharePoint column formatting for the governance Status columns.

Reads branding/status-map.json, checks it against sharepoint/list-schema.json
(every choice mapped, no value that isn't a choice), and writes one column
formatting JSON per list to branding/column-formats/. With --check it writes
nothing and fails if a generated file is missing or out of date, so a renamed
status or a hand edit fails CI.

Usage: python solutions/SharePointGovernance/tools/build_formatters.py [--check] [--root SOLUTION_DIR]

--root points it at another solution with the same branding/ layout
(solutions/SharePointNews).
"""
import json
import re
import sys
from pathlib import Path

def _root():
    if "--root" in sys.argv:
        return Path(sys.argv[sys.argv.index("--root") + 1]).resolve()
    return Path(__file__).resolve().parent.parent


ROOT = _root()
BRANDING = ROOT / "branding"
OUT = BRANDING / "column-formats"
SCHEMA = json.loads((ROOT / "sharepoint" / "list-schema.json").read_text())
STATUS_MAP = json.loads((BRANDING / "status-map.json").read_text())

FORMAT_SCHEMA = "https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json"


def choices(list_title, field):
    for lst in SCHEMA["lists"]:
        if lst["listTitle"] == list_title:
            for f in lst["fields"]:
                if f["internalName"] == field and f["type"] == "Choice":
                    return f["choices"]
    return None


def pick(groups, outcomes, prop):
    """Nested if() choosing an outcome colour; the last outcome is the fallback."""
    expr = f"'{outcomes['neutral'][prop]}'"
    for outcome in ("info", "bad", "good"):
        values = groups.get(outcome)
        if values:
            haystack = "|" + "|".join(values) + "|"
            expr = f"if(indexOf('{haystack}', '|' + @currentField + '|') >= 0, '{outcomes[outcome][prop]}', {expr})"
    return expr


def formatter(mapping, outcomes):
    groups = {}
    for value, outcome in mapping.items():
        groups.setdefault(outcome, []).append(value)
    return {
        "$schema": FORMAT_SCHEMA,
        "elmType": "div",
        "txtContent": "@currentField",
        "style": {
            "display": "=if(@currentField == '', 'none', 'inline-block')",
            "box-sizing": "border-box",
            "padding": "1px 10px",
            "border-radius": "8px",
            "font-size": "13px",
            "line-height": "20px",
            "white-space": "nowrap",
            "background-color": "=" + pick(groups, outcomes, "fill"),
            "color": "=" + pick(groups, outcomes, "ink"),
            "border": "='1px solid ' + " + pick(groups, outcomes, "stroke"),
        },
    }


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def main():
    check = "--check" in sys.argv[1:]
    outcomes = STATUS_MAP["outcomes"]
    errors, outputs = [], {}
    for col in STATUS_MAP["columns"]:
        name = f"{col['list']}.{col['field']}"
        defined = choices(col["list"], col["field"])
        if defined is None:
            errors.append(f"{name}: no such Choice column in list-schema.json")
            continue
        for value in defined:
            if value not in col["map"]:
                errors.append(f"{name}: choice '{value}' has no outcome")
        for value, outcome in col["map"].items():
            if value not in defined:
                errors.append(f"{name}: '{value}' is not a choice")
            if outcome not in outcomes:
                errors.append(f"{name}: '{value}' maps to unknown outcome '{outcome}'")
            if "'" in value or "|" in value:
                errors.append(f"{name}: '{value}' contains ' or |, which the formatter can't match")
        path = OUT / f"{slug(col['list'])}-{slug(col['field'])}.json"
        outputs[path] = json.dumps(formatter(col["map"], outcomes), indent=2) + "\n"

    if not errors:
        for path, text in outputs.items():
            rel = path.relative_to(ROOT)
            if check:
                if not path.exists() or path.read_text() != text:
                    errors.append(f"{rel} is out of date: run tools/build_formatters.py")
            else:
                path.parent.mkdir(exist_ok=True)
                path.write_text(text)
                print(f"wrote {rel}")

    for e in errors:
        print(f"ERROR {e}")
    if not errors and check:
        print(f"OK {len(outputs)} column formats match status-map.json")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()

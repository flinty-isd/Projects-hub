"""Static checks for the governance dashboard (sharepoint/dashboard.json).

Catches what SharePoint only reports when the provisioning script runs: views
on lists that don't exist, fields the schema doesn't define, choice values in
a CAML filter that the column doesn't offer, and two panels in one page slot.

Also checks every column formatter file parses, and that a view showing a
formatted column includes the columns that formatter reads (requiresInView).

Usage: python solutions/SharePointGovernance/tools/validate_dashboard.py [--root SOLUTION_DIR]

--root points the checks at another solution folder with sharepoint/dashboard.json
(e.g. solutions/EnterprisePMO); the default is SharePointGovernance.
"""
import json
import re
import sys
from pathlib import Path

ROOT = (Path(sys.argv[sys.argv.index("--root") + 1]).resolve() if "--root" in sys.argv
        else Path(__file__).resolve().parent.parent)
SCHEMA = json.loads((ROOT / "sharepoint" / "list-schema.json").read_text())
DASH = json.loads((ROOT / "sharepoint" / "dashboard.json").read_text())
# Governance uses one status badge on statusColumns; other solutions list formatters by file.
FORMATTERS = DASH.get("formatters") or [{"file": "status-format.json", "columns": DASH.get("statusColumns", [])}]
for fmt in FORMATTERS:
    json.loads((ROOT / "sharepoint" / fmt["file"]).read_text())

# Columns every list has; LinkTitle is the Title column with the item link.
BUILTIN = {"ID", "Title", "LinkTitle", "Created", "Modified", "Author", "Editor"}
FIELD_REF = re.compile(r'<FieldRef Name="([^"]+)"')
CHOICE_VALUE = re.compile(r'<FieldRef Name="([^"]+)"/>(?:<Values>)?((?:<Value Type="Choice">[^<]*</Value>)+)')
VALUE = re.compile(r'<Value Type="Choice">([^<]*)</Value>')


def main():
    lists = {l["listTitle"]: {f["internalName"]: f for f in l["fields"]} for l in SCHEMA["lists"]}
    builtin = {l["listTitle"]: set(l.get("builtinColumns", [])) for l in SCHEMA["lists"]}
    errors, slots, keys = [], {}, set()
    for v in DASH["views"]:
        where = f'{v["key"]} ({v["list"]} / {v["title"]})'
        if v["key"] in keys:
            errors.append(f"{where}: duplicate key")
        keys.add(v["key"])
        fields = lists.get(v["list"])
        if fields is None:
            errors.append(f"{where}: list not in list-schema.json")
            continue
        known = BUILTIN | builtin[v["list"]] | set(fields)
        for name in v["fields"] + FIELD_REF.findall(v["query"]):
            if name not in known:
                errors.append(f"{where}: unknown field {name}")
        for name, values in CHOICE_VALUE.findall(v["query"]):
            choices = set(fields.get(name, {}).get("choices", []))
            for value in VALUE.findall(values):
                if value not in choices:
                    errors.append(f"{where}: '{value}' is not a choice of {name}")
        for fmt in FORMATTERS:
            if any(l == v["list"] and c in v["fields"] for l, c in fmt["columns"]):
                for need in fmt.get("requiresInView", []):
                    if need not in v["fields"]:
                        errors.append(f"{where}: shows a column formatted by {fmt['file']}, which reads {need}; add {need} to the view")
        slot = (v["section"], v["column"])
        if slot in slots:
            errors.append(f"{where}: page slot {slot} already used by {slots[slot]}")
        slots[slot] = v["key"]
    for fmt in FORMATTERS:
        for list_title, column in fmt["columns"]:
            if column not in lists.get(list_title, {}):
                errors.append(f"{fmt['file']}: {list_title}.{column} not in list-schema.json")
    for e in errors:
        print("ERROR", e)
    print(f"dashboard.json: {len(DASH['views'])} views, {'ok' if not errors else f'{len(errors)} error(s)'}")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()

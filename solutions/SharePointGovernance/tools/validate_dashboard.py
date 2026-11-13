"""Static checks for the governance dashboard (sharepoint/dashboard.json).

Catches what SharePoint only reports when the provisioning script runs: views
on lists that don't exist, fields the schema doesn't define, choice values in
a CAML filter that the column doesn't offer, and two panels in one page slot.

Usage: python solutions/SharePointGovernance/tools/validate_dashboard.py
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = json.loads((ROOT / "sharepoint" / "list-schema.json").read_text())
DASH = json.loads((ROOT / "sharepoint" / "dashboard.json").read_text())
json.loads((ROOT / "sharepoint" / "status-format.json").read_text())

# Columns every list has; LinkTitle is the Title column with the item link.
BUILTIN = {"ID", "Title", "LinkTitle", "Created", "Modified", "Author", "Editor"}
FIELD_REF = re.compile(r'<FieldRef Name="([^"]+)"')
CHOICE_VALUE = re.compile(r'<FieldRef Name="([^"]+)"/>(?:<Values>)?((?:<Value Type="Choice">[^<]*</Value>)+)')
VALUE = re.compile(r'<Value Type="Choice">([^<]*)</Value>')


def main():
    lists = {l["listTitle"]: {f["internalName"]: f for f in l["fields"]} for l in SCHEMA["lists"]}
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
        known = BUILTIN | set(fields)
        for name in v["fields"] + FIELD_REF.findall(v["query"]):
            if name not in known:
                errors.append(f"{where}: unknown field {name}")
        for name, values in CHOICE_VALUE.findall(v["query"]):
            choices = set(fields.get(name, {}).get("choices", []))
            for value in VALUE.findall(values):
                if value not in choices:
                    errors.append(f"{where}: '{value}' is not a choice of {name}")
        slot = (v["section"], v["column"])
        if slot in slots:
            errors.append(f"{where}: page slot {slot} already used by {slots[slot]}")
        slots[slot] = v["key"]
    for list_title, column in DASH["statusColumns"]:
        if column not in lists.get(list_title, {}):
            errors.append(f"statusColumns: {list_title}.{column} not in list-schema.json")
    for e in errors:
        print("ERROR", e)
    print(f"dashboard.json: {len(DASH['views'])} views, {'ok' if not errors else f'{len(errors)} error(s)'}")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()

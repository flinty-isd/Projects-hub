"""Write list-csv/: one CSV per list for SharePoint's "Create a list > From CSV", and a guide per site.

For people who can't run the PnP provisioning scripts (no PnP app registration / client ID). Any
Site Owner can create a list from a CSV in the browser. The CSVs are generated from every
solution's sharepoint/list-schema.json, so they always match what the flows are checked against.

Why the files look the way they do:
  * Headers are the INTERNAL column names. SharePoint fixes a column's internal name from the CSV
    header when the list is created, and the flows find columns by internal name. After the import,
    rename each column's display name (that never changes the internal name).
  * Example rows cycle through every choice value, so a column imported as Choice gets all its
    options from the data. The rows' titles say EXAMPLE: delete them after the import.
  * What a CSV can't create is listed in each site's README instead: lookup and managed-metadata
    columns (added by hand after the import), document libraries and calendars, Site Pages, and
    lists that already exist (the live SP_MigrationRegister).

Usage:
  python solutions/SharePointGovernance/tools/build_list_csvs.py           # rewrite list-csv/
  python solutions/SharePointGovernance/tools/build_list_csvs.py --check   # CI: fail if out of date
"""
import csv
import io
import json
import re
import sys
from pathlib import Path

SOLUTIONS = Path(__file__).resolve().parents[2]
OUT = SOLUTIONS / "SharePointGovernance" / "list-csv"


def schema(solution):
    return json.loads((SOLUTIONS / solution / "sharepoint" / "list-schema.json").read_text())["lists"]


GOV, NEWS, PMO, CC, PORTAL = (schema(s) for s in
                              ("SharePointGovernance", "SharePointNews", "EnterprisePMO", "SharePointControlCentre", "PortalSnapshots"))
portal = lambda site: [l for l in PORTAL if l.get("site") == site and not l.get("existing")]

# folder, site name, [(set folder or "", solution, lists, other_news)]
SITES = [
    ("governance", "IT Enterprise Governance site", [("", "SharePointGovernance", GOV, False), ("", "PortalSnapshots", portal("governance"), False)]),
    ("hpuk-news", "HPUK News site", [("", "SharePointNews", [l for l in NEWS if "HPUK News" in (l.get("sites") or [])], False)]),
    ("other-news", "Other News site", [("", "SharePointNews", [l for l in NEWS if "Other News" in (l.get("sites") or [])], True)]),
    ("projects", "Projects site", [("pmo", "EnterprisePMO", PMO, False), ("controlcentre", "SharePointControlCentre", CC, False),
                                   ("board", "PortalSnapshots", portal("board"), False)]),
    ("asset-management", "Asset Management site", [("", "PortalSnapshots", portal("asset"), False)]),
]

NOT_IN_CSV = {"Lookup": "lookup", "Taxonomy": "managed metadata"}
IMPORT_TYPE = {"Text": "Single line of text", "Note": "Multiple lines of text", "Number": "Number", "Boolean": "Yes/No",
               "Choice": "Choice", "MultiChoice": "Choice (allow multiple selections)", "Person": "Person",
               "URL": "Hyperlink", "DateOnly": "Date and time (date only)"}


def import_type(f):
    if f["type"] == "DateTime":
        return "Date and time" + (" (date only)" if f.get("format") == "DateOnly" else " (include time)")
    return IMPORT_TYPE.get(f["type"], f["type"])


def iname(f, other):
    return (f.get("otherNewsInternalName") or f["internalName"]) if other else f["internalName"]


def file_name(title):
    return re.sub(r"[^A-Za-z0-9]+", "_", title).strip("_") + ".csv"


def csv_kind(l):
    """None if a CSV can create the list, else why not."""
    if l["listTitle"] == "Site Pages":
        return "built into every site (add the columns in the library's settings)"
    if l.get("existingOnly") or l["listTitle"] == "SP_MigrationRegister":
        return "already exists (live list): add only the missing columns, by hand"
    t = l.get("template") or "GenericList"
    if t == "DocumentLibrary":
        return "a document library: create it with New > Document library, then add the columns"
    if t == "Events":
        return "a calendar: create it with New > App > Calendar (Events), then add the columns"
    return None


def example(f, i):
    t, ch = f["type"], f.get("choices")
    if ch:
        return ch[i % len(ch)]
    if t == "Number":
        return str(f["default"]) if f.get("default") not in (None, "") else "1"
    if t == "Boolean":
        d = str(f.get("default", "0")).lower()
        return "Yes" if d in ("1", "true", "yes") else "No"
    if t in ("DateTime", "DateOnly"):
        return "2026-12-01" if (f.get("format") == "DateOnly" or t == "DateOnly") else "2026-12-01 09:00"
    if t == "URL":
        return "https://example.com"
    if t == "Person":
        return ""  # set the type to Person in the import screen; pick people after
    if t == "Note":
        return "Example text"
    return "Example"


def list_csv(l, other):
    fields = [f for f in l["fields"] if f["type"] not in NOT_IN_CSV and f["internalName"] != "Title"]
    title = next((f for f in l["fields"] if f["internalName"] == "Title"), None)
    rows = max([len(f["choices"]) for f in fields if f.get("choices")] + [2])
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\r\n")
    w.writerow(["Title"] + [iname(f, other) for f in fields])
    for i in range(rows):
        w.writerow([f"EXAMPLE {i + 1} - delete after import"] + [example(f, i) for f in fields])
    return "﻿" + buf.getvalue(), fields, title


def esc(s):
    return str(s).replace("|", "/").replace("\n", " ")


def list_section(l, other, fname):
    why = csv_kind(l)
    lines = [f"### {l['listTitle']}", ""]
    if l.get("listDescription"):
        lines += [esc(l["listDescription"]), ""]
    if why:
        lines += [f"**No CSV: {why}.** Add these columns by hand (*Add column*), using the internal name as the first name you type, then rename:", ""]
        cols = [f for f in l["fields"] if f["internalName"] != "Title"]
    else:
        _, cols, title = list_csv(l, other)
        rows = max([len(f["choices"]) for f in cols if f.get("choices")] + [2])
        lines += [f"**CSV:** `{fname}`. *New > List > From CSV*, name the list exactly **{l['listTitle']}**, then set each column's type as below. "
                  f"After it's created, delete the {rows} EXAMPLE rows."]
        if title and title["displayName"] != "Title":
            lines += ["", f"Rename the **Title** column to **{esc(title['displayName'])}**."]
        lines += [""]
        extra = [f for f in l["fields"] if f["type"] in NOT_IN_CSV]
        if extra:
            lines += ["**Add by hand after the import** (a CSV can't create these): " +
                      "; ".join(f"`{iname(f, other)}` ({NOT_IN_CSV[f['type']]}"
                                + (f" to {f['lookupList']}" if f.get("lookupList") else "")
                                + (f", term set {f['termSet']}" if f.get("termSet") else "") + ")" for f in extra) + ".", ""]
    lines += ["| CSV header = internal name | Type to choose | Then rename to | Required | Choices / default | After import |",
              "|---|---|---|---|---|---|"]
    for f in cols:
        after = []
        if f.get("flowManaged") or f.get("hideOnNewForm"):
            after.append("hide from the new" + (" and edit" if f.get("flowManaged") else "") + " form")
        if f.get("indexed"):
            after.append("index it")
        if f["type"] in NOT_IN_CSV:
            after.append("add by hand")
        ch = ", ".join(f["choices"]) if f.get("choices") else ""
        if f.get("default") not in (None, ""):
            dflt = f["default"]
            if f["type"] == "Boolean":
                dflt = "Yes" if str(dflt).lower() in ("1", "true", "yes") else "No"
            ch = (ch + "; " if ch else "") + f"default {dflt}"
        if f.get("lookupList"):
            ch = f"lookup to {f['lookupList']} ({f.get('lookupField', 'Title')})"
        if f.get("termSet"):
            ch = f"term set {f['termSet']}"
        rename = esc(f["displayName"]) if f["displayName"] != iname(f, other) else ""
        lines.append(f"| `{iname(f, other)}` | {esc(import_type(f) if f['type'] not in NOT_IN_CSV else NOT_IN_CSV[f['type']])} | {rename} | "
                     f"{'Yes' if f.get('required') else ''} | {esc(ch)} | {'; '.join(after)} |")
    return lines + [""]


STEPS = """## How to import a list

1. On the site, select **New > List > From CSV** (or **Lists > New list > From CSV**) and pick the file.
2. Name the list **exactly** as given below. The flows find lists by name.
3. In the preview, set each column's **type** from the table. Leave the column names as the
   headers (they are the internal names the flows use). If a column offers a choice of title
   column, use **Title**.
4. **Create.** Then, in the list:
   - delete the EXAMPLE rows
   - in **List settings**, for each column: rename it to the display name in the table, tick
     *Require that this column contains information* where Required says Yes, set the default,
     and check the choices
   - hide the columns marked *hide from the new / edit form* (*Edit columns* on the form, or
     the column's settings)
   - add the columns marked *add by hand*
   - index the columns marked *index it* (*List settings > Indexed columns*)
   - turn on **Versioning** (*List settings > Versioning settings*)
5. **Check the internal names.** Open each column's settings: the address ends `Field=<internal
   name>`, which must match the table exactly. A header SharePoint already uses gets a number
   added (for example `Category0`). If that happens, delete the column and add it by hand with the
   internal name.

Create lists that others look up first (the order below already does this).
"""


def site_readme(folder, name, groups):
    lines = [f"# {name}: create the lists from CSV", "",
             "<!-- Generated by SharePointGovernance/tools/build_list_csvs.py from the solutions' list-schema.json. Don't edit. -->", "",
             "For Site Owners without the PnP provisioning scripts (no client ID needed). Each CSV makes one list with the "
             "columns the flows expect. The provisioning scripts do the same thing automatically, so use one route or the other, not both.", "",
             STEPS]
    for set_folder, solution, lists, other in groups:
        if set_folder:
            lines += [f"## Set `{set_folder}` ({solution})", ""]
        elif len(groups) > 1:
            lines += [f"## {solution}", ""]
        else:
            lines += ["## Lists", ""]
        for l in lists:
            rel = (f"{set_folder}/" if set_folder else "") + file_name(l["listTitle"])
            lines += list_section(l, other, rel)
    if folder == "governance":
        lines += ["## ISO 27001", "", "ISO 27001 controls go in the **Compliance Register** above (Framework = ISO 27001). There is no separate ISO list.", ""]
    if folder == "projects":
        lines += ["## Overlapping lists", "",
                  "Each set has its own RAID log (Master RAID Log, SP_RAID, Programme RAID) and decisions list (Action and Decision Tracker, "
                  "SP_Decisions, Board Decisions). Agree which is the master before creating more than one set on the site.", ""]
    return "\n".join(lines)


def outputs():
    files = {}
    index = ["# List CSVs", "",
             "<!-- Generated by SharePointGovernance/tools/build_list_csvs.py. Don't edit: change a schema and run the script. -->", "",
             "One CSV per list for SharePoint's **New > List > From CSV**, by site, for people who can't run the PnP provisioning "
             "scripts (no client ID). Each folder's README says how to import, the name to give each list, the type to choose for each "
             "column, and what to add by hand afterwards (lookup and managed-metadata columns, libraries, calendars).", "",
             "| Site | Folder | CSVs | Created by hand |", "|---|---|---|---|"]
    for folder, name, groups in SITES:
        n_csv, manual = 0, []
        for set_folder, _sol, lists, other in groups:
            for l in lists:
                if csv_kind(l):
                    manual.append(l["listTitle"])
                    continue
                text, _, _ = list_csv(l, other)
                files[f"{folder}/{set_folder + '/' if set_folder else ''}{file_name(l['listTitle'])}"] = text
                n_csv += 1
        files[f"{folder}/README.md"] = site_readme(folder, name, groups)
        index.append(f"| {name} | `{folder}/` | {n_csv} | {', '.join(manual) or '-'} |")
    index += ["", "The headers are internal column names on purpose: keep them as they are, and rename the display names after the import. "
              "ISO 27001 controls go in the governance site's Compliance Register."]
    files["README.md"] = "\n".join(index) + "\n"
    return files


def main():
    files = outputs()
    if "--check" in sys.argv:
        stale = [p for p, t in files.items() if not (OUT / p).exists() or (OUT / p).read_bytes().decode("utf-8") != t]
        extra = [str(p.relative_to(OUT)) for p in OUT.rglob("*") if p.is_file() and str(p.relative_to(OUT)) not in files] if OUT.exists() else []
        if stale or extra:
            sys.exit(f"list-csv/ out of date (changed: {stale}, unexpected: {extra}): run python solutions/SharePointGovernance/tools/build_list_csvs.py")
        print(f"list-csv: {len(files)} files up to date")
        return
    if OUT.exists():
        for p in OUT.rglob("*"):
            if p.is_file() and str(p.relative_to(OUT)) not in files:
                p.unlink()
    for p, t in files.items():
        (OUT / p).parent.mkdir(parents=True, exist_ok=True)
        (OUT / p).write_text(t, encoding="utf-8", newline="")
    print(f"Wrote {sum(p.endswith('.csv') for p in files)} CSVs and {sum(p.endswith('.md') for p in files)} guides under SharePointGovernance/list-csv/")


if __name__ == "__main__":
    main()

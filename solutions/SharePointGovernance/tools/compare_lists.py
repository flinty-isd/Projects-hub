"""Compare what is on a SharePoint site with the repository's list schemas, and say what's missing.

For sites where some lists were already created by hand. Needs no client ID or script on the
SharePoint side: open this address in a browser signed in to the site (Read access is enough),
save the page (Ctrl+S) and give the file to this tool:

  https://<tenant>.sharepoint.com/sites/<site>/_api/web/lists?$filter=Hidden eq false&$expand=Fields&$select=Title,BaseTemplate,Fields/InternalName,Fields/Title,Fields/TypeAsString,Fields/Required,Fields/Hidden

The browser gets XML (Atom); a JSON response (from Power Automate or PnP) works too.

The report says, per list the schema expects on that site:
  * missing list: create it (list-csv/ CSV, or by hand for libraries and calendars)
  * missing column: add it, with the internal name, type and settings to use
  * column created under the wrong internal name (e.g. Asset_x0020_tag or Category0 where the flows
    expect AssetTag or Category): the flows won't find it; delete it and add it again correctly
  * wrong type (e.g. Text where the flows expect Choice)
  * required flag that differs
Extra lists and columns on the site are listed but never treated as errors.

Usage:
  python solutions/SharePointGovernance/tools/compare_lists.py --site projects --sets pmo,board saved-lists.xml [--out report.md]
  sites: governance, hpuk-news, other-news, projects (sets pmo, controlcentre, board), asset-management
"""
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_list_csvs import SITES, NOT_IN_CSV, csv_kind, file_name, iname, import_type  # noqa: E402

D = "{http://schemas.microsoft.com/ado/2007/08/dataservices}"
M = "{http://schemas.microsoft.com/ado/2007/08/dataservices/metadata}"
A = "{http://www.w3.org/2005/Atom}"

# Schema type -> SharePoint TypeAsString values that satisfy it
SP_TYPES = {"Text": {"Text"}, "Note": {"Note"}, "Number": {"Number", "Currency"}, "DateTime": {"DateTime"}, "DateOnly": {"DateTime"},
            "Boolean": {"Boolean"}, "Choice": {"Choice"}, "MultiChoice": {"MultiChoice"}, "Person": {"User", "UserMulti"},
            "Lookup": {"Lookup", "LookupMulti"}, "URL": {"URL"}, "Taxonomy": {"TaxonomyFieldType", "TaxonomyFieldTypeMulti"}}


def _bool(v):
    return str(v).strip().lower() in ("true", "1")


def parse(path):
    """-> {list title: {"template": int, "fields": {internal: {"title", "type", "required", "hidden"}}}}"""
    raw = Path(path).read_bytes().decode("utf-8-sig", errors="replace").strip()
    site = {}
    if raw.startswith("{"):
        doc = json.loads(raw)
        rows = doc.get("value") or doc.get("d", {}).get("results") or []
        for r in rows:
            fields = r.get("Fields") or {}
            fields = fields.get("results", fields) if isinstance(fields, dict) else fields
            site[r["Title"]] = {"template": int(r.get("BaseTemplate") or 0),
                                "fields": {f["InternalName"]: {"title": f.get("Title", ""), "type": f.get("TypeAsString", ""),
                                                               "required": _bool(f.get("Required")), "hidden": _bool(f.get("Hidden"))} for f in fields}}
        return site
    root = ET.fromstring(raw)
    for entry in root.findall(f"{A}entry"):
        props = entry.find(f"{A}content/{M}properties")
        if props is None:
            continue
        title = props.findtext(f"{D}Title", "")
        fields = {}
        for fe in entry.iter(f"{A}entry"):
            if fe is entry:
                continue
            fp = fe.find(f"{A}content/{M}properties")
            if fp is None or fp.find(f"{D}InternalName") is None:
                continue
            fields[fp.findtext(f"{D}InternalName")] = {"title": fp.findtext(f"{D}Title", ""), "type": fp.findtext(f"{D}TypeAsString", ""),
                                                       "required": _bool(fp.findtext(f"{D}Required", "false")),
                                                       "hidden": _bool(fp.findtext(f"{D}Hidden", "false"))}
        site[title] = {"template": int(props.findtext(f"{D}BaseTemplate", "0") or 0), "fields": fields}
    return site


def rename(f, want):
    return f", then rename it to *{f['displayName']}*" if f["displayName"] != want else ""


def encoded(name):
    """How SharePoint encodes a display name typed with spaces: 'Asset tag' -> 'Asset_x0020_tag'."""
    return name.replace(" ", "_x0020_")


def wrong_name(expected, f, actual_fields):
    """A field that looks like the expected one created under another internal name."""
    cands = []
    for n, a in actual_fields.items():
        if n == expected:
            continue
        if re.fullmatch(re.escape(expected) + r"\d+", n) or n == encoded(f["displayName"])[:32] or \
                (a["title"].lower() in (f["displayName"].lower(), expected.lower()) and n not in ("Title",)):
            cands.append(n)
    return cands


def compare(site_key, sets, actual):
    folder, name, groups = next(s for s in SITES if s[0] == site_key)
    lines = [f"# {name}: what's missing", "",
             f"Compared the lists saved from the site with the repository schemas ({', '.join(sets) if sets else 'all lists for this site'}).", ""]
    summary = {"lists_ok": 0, "lists_missing": 0, "columns_missing": 0, "wrong_name": 0, "wrong_type": 0, "required": 0}
    expected_titles = set()
    for set_folder, solution, lists, other in groups:
        if sets and set_folder and set_folder not in sets:
            continue
        if set_folder:
            lines += [f"## Set `{set_folder}` ({solution})", ""]
        for l in lists:
            title = l["listTitle"]
            expected_titles.add(title)
            got, problems = actual.get(title), []
            if got is None:
                case = next((t for t in actual if t.lower() == title.lower()), None)
                if case:
                    # Same list, different capitalisation: rename it, then check its columns as normal.
                    expected_titles.add(case)
                    got = actual[case]
                    problems.append(f"| (list name) | **Rename the list** from *{case}* to **{title}** (List settings > List name): the flows find lists by exact name. |")
            if got is None:
                summary["lists_missing"] += 1
                how = csv_kind(l) or f"import `{(set_folder + '/') if set_folder else ''}{file_name(title)}` from list-csv/{folder}/ (New > List > From CSV)"
                lines += [f"### {title}: missing", "", f"Not on the site. Create it: {how}.", ""]
                continue
            for f in l["fields"]:
                want = iname(f, other)
                if want == "Title":
                    continue
                a = got["fields"].get(want)
                if a is None:
                    alt = wrong_name(want, f, got["fields"])
                    if alt:
                        summary["wrong_name"] += 1
                        problems.append(f"| `{want}` | **Created under the wrong internal name** `{', '.join(alt)}`: the flows won't find it. "
                                        f"Delete it and add the column again, typing `{want}` as the name first{rename(f, want)}. "
                                        f"(Move any data across first.) |")
                    else:
                        summary["columns_missing"] += 1
                        kind = NOT_IN_CSV.get(f["type"]) or import_type(f)
                        detail = f" to {f['lookupList']}" if f.get("lookupList") else (f", term set {f['termSet']}" if f.get("termSet") else "")
                        detail += f"; choices: {', '.join(f['choices'])}" if f.get("choices") else ""
                        problems.append(f"| `{want}` | **Missing.** Add a {kind} column{detail}. Type `{want}` as the name first"
                                        f"{rename(f, want)}{'; required' if f.get('required') else ''}. |")
                    continue
                ok = SP_TYPES.get(f["type"], {f["type"]})
                if a["type"] not in ok:
                    summary["wrong_type"] += 1
                    problems.append(f"| `{want}` | **Wrong type:** it is {a['type']}, the flows expect {f['type']}. Change the type in its settings "
                                    f"if SharePoint allows it; otherwise delete and re-add it (move the data first). |")
                if bool(f.get("required")) != a["required"] and not f.get("flowManaged"):
                    summary["required"] += 1
                    problems.append(f"| `{want}` | Required is {'off' if f.get('required') else 'on'}; set it {'on' if f.get('required') else 'off'}. |")
            if problems:
                lines += [f"### {title}: {len(problems)} to fix", "", "| Column | What to do |", "|---|---|"] + problems + [""]
            else:
                summary["lists_ok"] += 1
                lines += [f"### {title}: matches", ""]
    extra = sorted(t for t in actual if t not in expected_titles and actual[t]["template"] in (100, 101, 106))
    if extra:
        lines += ["## Other lists on the site", "", "Not in the schemas for this site (left alone): " + ", ".join(extra) + ".", ""]
    head = (f"**{summary['lists_ok']}** lists match, **{summary['lists_missing']}** missing; "
            f"**{summary['columns_missing']}** columns missing, **{summary['wrong_name']}** under the wrong internal name, "
            f"**{summary['wrong_type']}** of the wrong type, **{summary['required']}** with the wrong required setting.")
    lines.insert(4, head)
    lines.insert(5, "")
    return "\n".join(lines) + "\n", summary


def main():
    args = sys.argv[1:]
    if "--site" not in args or len([a for a in args if not a.startswith("--")]) < 2:
        sys.exit(__doc__)
    site = args[args.index("--site") + 1]
    sets = args[args.index("--sets") + 1].split(",") if "--sets" in args else []
    files = [a for i, a in enumerate(args) if not a.startswith("--") and (i == 0 or args[i - 1] not in ("--site", "--sets", "--out"))]
    actual = {}
    for p in files:
        actual.update(parse(p))
    report, summary = compare(site, sets, actual)
    if "--out" in args:
        Path(args[args.index("--out") + 1]).write_text(report, encoding="utf-8")
    print(report)


if __name__ == "__main__":
    main()

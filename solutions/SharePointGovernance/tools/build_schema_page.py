"""Write pages/HPUK-List-Schemas.html: every SharePoint list and column in the repository, by site.

The page is built only from the solutions' sharepoint/list-schema.json files (and their
solution-config.json versions), so it always shows the internal names and choices the flows,
provisioning scripts and the projects-site skill are checked against. Don't edit the HTML: change a
schema and run this again.

It is a static page for the IT Enterprise Governance site's Site Pages library (a SharePoint HTML
page): inline CSS only, no JavaScript, no external fonts or files, so it works in the HTML page
sandbox and keeps to the no-custom-script rule (G-02). Sites are sections with a contents bar;
lists are collapsible; use the browser's find (Ctrl+F) to search.

Usage:
  python solutions/SharePointGovernance/tools/build_schema_page.py           # rewrite the page
  python solutions/SharePointGovernance/tools/build_schema_page.py --check   # CI: fail if out of date
"""
import json
import sys
from html import escape
from pathlib import Path

SOLUTIONS = Path(__file__).resolve().parents[2]
OUT = SOLUTIONS / "SharePointGovernance" / "pages" / "HPUK-List-Schemas.html"


def schema(solution):
    return json.loads((SOLUTIONS / solution / "sharepoint" / "list-schema.json").read_text())["lists"]


def version(solution):
    cfg = SOLUTIONS / solution / "solution-config.json"
    return json.loads(cfg.read_text())["version"] if cfg.exists() else None


GOV, NEWS, PMO, CC, PORTAL = (schema(s) for s in
                              ("SharePointGovernance", "SharePointNews", "EnterprisePMO", "SharePointControlCentre", "PortalSnapshots"))


def portal(site, existing=False):
    return [l for l in PORTAL if l.get("site") == site and bool(l.get("existing")) == existing]


# Each site: (anchor, name, location, summary, [(group, solution, note, lists, other_news_names)], extra panel)
SITES = [
    ("governance", "IT Enterprise Governance site", "/sites/hpuk-pof-it-enterprisegovernance (example)",
     "The governance and security registers the governance flows run against, and the registers the IT Governance portal is refreshed from.",
     [("Governance service", "SharePointGovernance", "Governance flows 01 to 08 and the governance dashboard.", GOV, False),
      ("Portal registers", "PortalSnapshots", "Read by portal flow P3 for the IT Governance portal. P3 also reads the Site Register and Decision Log above.", portal("governance"), False)], None),
    ("hpuk-news", "HPUK News site", "/teams/hpuk-pof-HPUKNEWS",
     "News pages, attachments, videos, the archive, and the distribution and delivery lists for the weekly roundup and urgent alerts.",
     [("News and notices", "SharePointNews", "News flows C1, C2 and C3a.", [l for l in NEWS if "HPUK News" in (l.get("sites") or [])], False)], None),
    ("other-news", "Other News site", "/teams/hpuk-pof-OTHERNEWS",
     "Shares the page columns with HPUK News. Where a column has a different internal name on this site, that name is shown.",
     [("News and notices", "SharePointNews", "News flows C1 and C3b. Distribution and delivery lists live on HPUK News.", [l for l in NEWS if "Other News" in (l.get("sites") or [])], True)], None),
    ("projects", "Projects site", "/sites/hpuk-pof-projects",
     "Project management lists in three sets. The hpuk-projects-site-lists skill creates any combination of them.",
     [("Enterprise PMO hub", "EnterprisePMO", "Set pmo. PMO flows 01 to 05 and the Portfolio Governance Hub page.", PMO, False),
      ("Project Control Centre", "SharePointControlCentre", "Set controlcentre. The Control Centre pages and Power App. SP_MigrationRegister is the live register: checked, never created.", CC, False),
      ("Control Board", "PortalSnapshots", "Set board. Read by portal flow P2 for the Project Management Control Board.", portal("board"), False)],
     ("The three sets overlap. Each has its own RAID log and decisions list, so agree which is the master before creating more than one set on the site.",
      [("RAID log", "Master RAID Log", "SP_RAID", "Programme RAID"),
       ("Decisions", "Action and Decision Tracker", "SP_Decisions", "Board Decisions"),
       ("Actions", "Action and Decision Tracker", "SP_Actions", "-")])),
    ("asset-management", "Asset Management site", "The asset site (PortalAssetSiteUrl in PortalSnapshots)",
     "The asset register and asset service requests behind the Asset Management portal, republished by portal flow P1 on weekdays at 06:30 and 12:30.",
     [("Asset Management portal", "PortalSnapshots", "Read by portal flow P1. The portal ignores a snapshot with no assets, so fill the Asset Register before switching P1 on.", portal("asset"), False)], None),
    ("iso27001", "ISO 27001", "Compliance Register on the IT Enterprise Governance site",
     "ISO 27001 isn't a separate site. Controls are tracked in the Compliance Register, one row per control, and shown on the IT Governance portal's Compliance tab. Framework is free text, so filter on Framework = ISO 27001. Only Compliant counts as compliant on the portal.",
     [("Compliance Register", "PortalSnapshots", "The same list as in the governance site section, repeated here for ISO 27001.",
       [l for l in PORTAL if l["listTitle"] == "Compliance Register"], False)], None),
]

TEMPLATES = {"GenericList": "List", "DocumentLibrary": "Document library", "Events": "Calendar (Events)"}
GOOD = {"Compliant"}
BAD = {"Non-Compliant"}


def type_label(f):
    t = f["type"]
    if t == "DateTime":
        return "Date" if f.get("format") == "DateOnly" else "Date and time"
    return {"Text": "Text", "Note": "Multi-line text", "Boolean": "Yes/No", "Choice": "Choice", "MultiChoice": "Choices (several)",
            "Person": "Person", "Lookup": "Lookup", "URL": "Link", "DateOnly": "Date",
            "Taxonomy": "Managed metadata" + (" (several)" if f.get("multi") else ""),
            "Number": "Number" + (f" ({f['decimals']} dp)" if f.get("decimals") else "")}.get(t, t)


def field_row(f, other_news, iso):
    name = (f.get("otherNewsInternalName") or f["internalName"]) if other_news else f["internalName"]
    tags = ""
    if f.get("flowManaged"):
        tags += '<span class="tag info">Set by flow</span>'
    if f.get("hidden"):
        tags += '<span class="tag info">Hidden</span>'
    if f.get("indexed"):
        tags += '<span class="chip">Indexed</span>'
    detail = ""
    if f.get("choices"):
        def cls(c):
            if iso and f["internalName"] == "ComplianceStatus":
                return "tag good" if c in GOOD else "tag bad" if c in BAD else "tag info"
            return "chip"
        detail += '<div class="chips">' + "".join(f'<span class="{cls(c)}">{escape(c)}</span>' for c in f["choices"]) + "</div>"
    notes = []
    if f.get("lookupList"):
        notes.append(f"Looks up {escape(f['lookupList'])}")
    if f.get("termSet"):
        notes.append(f"Term set {escape(f['termSet'])}")
    if f.get("default") not in (None, ""):
        notes.append(f"Default {escape(str(f['default']))}")
    if f.get("notes"):
        notes.append(escape(f["notes"]))
    if notes:
        detail += '<div class="notes">' + " · ".join(notes) + "</div>"
    return (f"<tr><td>{escape(f['displayName'])}{'<div>' + tags + '</div>' if tags else ''}</td>"
            f'<td class="iname">{escape(name)}</td><td class="type">{escape(type_label(f))}</td>'
            f'<td class="req">{"Yes" if f.get("required") else ""}</td><td>{detail}</td></tr>')


def list_block(l, other_news, iso, open_):
    live = l.get("existingOnly") or l["listTitle"] == "SP_MigrationRegister"
    template = "Site Pages library" if l["listTitle"] == "Site Pages" else TEMPLATES.get(l.get("template") or "GenericList", l.get("template"))
    rows = "".join(field_row(f, other_news, iso) for f in l["fields"])
    return (f'<details class="list"{" open" if open_ else ""}><summary><span class="lt">{escape(l["listTitle"])}</span>'
            f'{" <span class=\"tag bad\">Live list</span>" if live else ""}'
            f'<span class="meta">{escape(template)} · {len(l["fields"])} columns</span></summary><div class="list-body">'
            f'{"<p>" + escape(l.get("listDescription", "")) + "</p>" if l.get("listDescription") else ""}'
            '<div class="table-wrap"><table><thead><tr><th>Column</th><th>Internal name</th><th>Type</th><th>Required</th>'
            f"<th>Choices and notes</th></tr></thead><tbody>{rows}</tbody></table></div></div></details>")


CSS = """
:root { --bg:#ffffff; --surface:#f0f2f6; --text:#31333f; --muted:#5c5f6e; --line:#dfe2ea; --primary:#ff4b4b; --chip:#e6e9f0;
  --good-fill:#dcfce7; --good-stroke:#15803d; --good-ink:#14532d; --bad-fill:#fee2e2; --bad-stroke:#b91c1c; --bad-ink:#7f1d1d;
  --info-fill:#e0f2fe; --info-stroke:#0369a1; --info-ink:#0c4a6e;
  --sans:"Source Sans 3","Source Sans Pro","Segoe UI",system-ui,-apple-system,Roboto,Arial,sans-serif;
  --mono:"Source Code Pro",Consolas,"Cascadia Mono",Menlo,monospace; --radius:0.5rem; }
@media (prefers-color-scheme: dark) { :root { --bg:#0e1117; --surface:#262730; --text:#fafafa; --muted:#a3a8b8; --line:#3a3c4a; --chip:#31333f; color-scheme:dark; } }
* { box-sizing:border-box; }
html { -webkit-text-size-adjust:100%; scroll-behavior:smooth; }
body { margin:0; background:var(--bg); color:var(--text); font:16px/1.6 var(--sans); }
.wrap { max-width:1100px; margin:0 auto; padding:28px 16px 64px; }
h1 { font-size:2.25rem; line-height:1.2; margin:0 0 6px; }
h2 { font-size:1.6rem; line-height:1.25; margin:0; }
h3 { font-size:1.25rem; line-height:1.3; margin:0; }
.lede { color:var(--muted); max-width:70ch; margin:0; }
code { font-family:var(--mono); font-size:0.86em; }
.stats { display:flex; flex-wrap:wrap; gap:6px 18px; margin-top:12px; color:var(--muted); font-size:0.95rem; }
.stats b { color:var(--text); }
nav.toc { position:sticky; top:0; z-index:2; display:flex; flex-wrap:wrap; gap:4px; margin:22px 0 0; padding:8px 0; background:var(--bg); border-bottom:1px solid var(--line); }
nav.toc a { color:var(--text); text-decoration:none; font-weight:600; font-size:0.95rem; padding:5px 11px; border-radius:var(--radius); }
nav.toc a:hover { background:var(--surface); }
nav.toc a span { font-family:var(--mono); font-size:0.78rem; color:var(--muted); margin-left:6px; font-weight:400; }
a:focus-visible, summary:focus-visible { outline:2px solid var(--primary); outline-offset:2px; }
section.site { padding-top:34px; scroll-margin-top:56px; display:grid; gap:10px; }
.where { font-family:var(--mono); font-size:0.88rem; color:var(--muted); overflow-wrap:anywhere; }
.group { margin-top:18px; display:grid; gap:10px; }
.group-head { display:flex; flex-wrap:wrap; gap:6px 12px; align-items:baseline; }
.group-note { color:var(--muted); margin:0; max-width:85ch; }
.sol { font-family:var(--mono); font-size:0.78rem; background:var(--chip); border-radius:6px; padding:1px 7px; color:var(--muted); }
details.list { border:1px solid var(--line); border-radius:var(--radius); }
details.list > summary { cursor:pointer; display:flex; flex-wrap:wrap; align-items:center; gap:6px 12px; padding:11px 14px; background:var(--surface); border-radius:var(--radius); }
details.list[open] > summary { border-radius:var(--radius) var(--radius) 0 0; border-bottom:1px solid var(--line); }
.lt { font-weight:700; font-size:1.05rem; }
.meta { color:var(--muted); font-size:0.9rem; }
.list-body { padding:12px 14px 14px; display:grid; gap:10px; min-width:0; }
.list-body p { margin:0; max-width:85ch; }
.table-wrap { overflow-x:auto; border:1px solid var(--line); border-radius:var(--radius); }
table { border-collapse:collapse; width:100%; font-size:0.93rem; }
th, td { text-align:left; vertical-align:top; padding:7px 10px; border-bottom:1px solid var(--line); }
tr:last-child td { border-bottom:0; }
th { font-size:0.78rem; letter-spacing:.05em; text-transform:uppercase; color:var(--muted); font-weight:600; background:var(--surface); white-space:nowrap; }
td.iname { font-family:var(--mono); font-size:0.84rem; white-space:nowrap; }
td.type { white-space:nowrap; }
td.req { font-weight:700; }
.notes { color:var(--muted); font-size:0.88rem; margin-top:3px; }
.chips { display:flex; flex-wrap:wrap; gap:4px; }
.chip { font-size:0.8rem; background:var(--chip); border-radius:6px; padding:0 7px; line-height:1.6; }
.tag { display:inline-block; font-size:0.74rem; font-weight:600; border:1px solid; border-radius:6px; padding:0 6px; line-height:1.55; margin:2px 4px 0 0; white-space:nowrap; }
.good { background:var(--good-fill); color:var(--good-ink); border-color:var(--good-stroke); }
.bad { background:var(--bad-fill); color:var(--bad-ink); border-color:var(--bad-stroke); }
.info { background:var(--info-fill); color:var(--info-ink); border-color:var(--info-stroke); }
.panel { background:var(--surface); border-radius:var(--radius); padding:12px 14px; display:grid; gap:8px; }
.panel p { margin:0; }
footer { margin-top:44px; color:var(--muted); font-size:0.9rem; max-width:85ch; }
@media (max-width:640px) { h1 { font-size:1.8rem; } h2 { font-size:1.35rem; } nav.toc { position:static; flex-wrap:nowrap; overflow-x:auto; } nav.toc a { white-space:nowrap; } section.site { scroll-margin-top:8px; } }
@media (prefers-reduced-motion: reduce) { html { scroll-behavior:auto; } }
@media print { nav.toc { position:static; } details.list > summary { background:none; } }
"""


def build():
    seen, total_cols = set(), 0
    for anchor, _name, _where, _summary, groups, _extra in SITES:
        if anchor == "iso27001":
            continue
        for _, sol, _, lists, _ in groups:
            for l in lists:
                if (l["listTitle"], sol) not in seen:
                    seen.add((l["listTitle"], sol))
                    total_cols += len(l["fields"])
    toc = "".join(f'<a href="#{a}">{escape(n.replace(" site", ""))}<span>{sum(len(g[3]) for g in gs)}</span></a>' for a, n, _, _, gs, _ in SITES)
    versions = ", ".join(f"{s} {version(s)}" if version(s) else s for s in
                         ("SharePointGovernance", "SharePointNews", "EnterprisePMO", "SharePointControlCentre", "PortalSnapshots"))
    body = []
    for anchor, name, where, summary, groups, extra in SITES:
        iso = anchor == "iso27001"
        n_lists = sum(len(g[3]) for g in groups)
        n_cols = sum(len(l["fields"]) for g in groups for l in g[3])
        part = [f'<section class="site" id="{anchor}"><h2>{escape(name)}</h2><div class="where">{escape(where)}</div>',
                f'<p class="lede">{escape(summary)} <b>{n_lists} lists, {n_cols} columns.</b></p>']
        if extra:
            text, rows = extra
            part.append('<div class="panel"><p>' + escape(text) + '</p><div class="table-wrap"><table><thead><tr><th>Role</th>'
                        '<th>Enterprise PMO hub</th><th>Project Control Centre</th><th>Control Board</th></tr></thead><tbody>'
                        + "".join("<tr>" + "".join(f"<td>{escape(c)}</td>" for c in r) + "</tr>" for r in rows) + "</tbody></table></div></div>")
        for gname, sol, note, lists, other in groups:
            part.append(f'<div class="group"><div class="group-head"><h3>{escape(gname)}</h3><span class="sol">{escape(sol)}</span></div>'
                        f'<p class="group-note">{escape(note)}</p>'
                        + "".join(list_block(l, other, iso, iso) for l in lists) + "</div>")
        part.append("</section>")
        body.append("".join(part))
    return f"""<!doctype html>
<html lang="en-GB">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="Every SharePoint list and column in the HPUK Projects-hub solutions, by site.">
<title>HPUK List Schemas</title>
<!-- Generated by SharePointGovernance/tools/build_schema_page.py from the solutions' list-schema.json files.
     Don't edit: change a schema and run the script. Static: inline CSS, no scripts, no external files. -->
<style>{CSS}</style>
</head>
<body>
<div class="wrap">
<header>
<h1>HPUK list schemas</h1>
<p class="lede">Every SharePoint list and column the HPUK flows, pages and scripts are built on, by site. These are the internal names and choices the flows are checked against. Open a list to see its columns; use your browser's find (Ctrl+F) to search.</p>
<div class="stats"><span><b>5</b> sites</span><span><b>{len(seen)}</b> lists</span><span><b>{total_cols}</b> columns</span><span>{escape(versions)}</span></div>
</header>
<nav class="toc" aria-label="Sites">{toc}</nav>
{"".join(body)}
<footer><p>Generated from the <code>list-schema.json</code> files in the Projects-hub repository. To change a list, change its schema in the owning solution (where the flows' validators check it) and regenerate this page; don't edit the page. Columns marked <span class="tag info">Set by flow</span> are hidden from the new and edit forms because a flow writes them. A <span class="tag bad">Live list</span> already exists and is never created by the scripts, only given missing columns.</p></footer>
</div>
</body>
</html>
"""


def main():
    html = build()
    if "--check" in sys.argv:
        if not OUT.exists() or OUT.read_text(encoding="utf-8") != html:
            sys.exit("pages/HPUK-List-Schemas.html is out of date: run python solutions/SharePointGovernance/tools/build_schema_page.py")
        print("HPUK-List-Schemas.html: up to date")
        return
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(html, encoding="utf-8")
    print(f"Wrote {OUT.relative_to(SOLUTIONS.parent)} ({len(html.encode()) // 1024} KB)")


if __name__ == "__main__":
    main()

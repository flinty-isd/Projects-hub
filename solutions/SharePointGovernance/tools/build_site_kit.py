"""Build the no-PowerShell kit for a solution's SharePoint site.

From the Hutchison Ports theme (SharePointGovernance/branding/theme), the
solution's branding/column-formats (run build_formatters.py first) and its
branding/pages/pages.json, writes:

  branding/browser/<pages.json "script">  one script to paste into the
      browser console on the site: applies the theme, formats the status
      columns, uploads the diagrams, creates and publishes the pages, adds
      them to the navigation
  branding/copilot/page-prompts.md  the same pages as Copilot in SharePoint
      prompts, for when the console is not an option

With --check it writes nothing and fails if either file is out of date.
--root points it at another solution with the same branding/ layout
(solutions/SharePointNews).

Usage: python solutions/SharePointGovernance/tools/build_site_kit.py [--check] [--root SOLUTION_DIR]
"""
import base64
import html
import json
import re
import struct
import sys
from pathlib import Path

def _root():
    if "--root" in sys.argv:
        return Path(sys.argv[sys.argv.index("--root") + 1]).resolve()
    return Path(__file__).resolve().parent.parent


ROOT = _root()
BRANDING = ROOT / "branding"
THEME_FILE = Path(__file__).resolve().parent.parent / "branding" / "theme" / "hutchison-ports-theme.json"
THEME = json.loads(THEME_FILE.read_text())
STATUS_MAP = json.loads((BRANDING / "status-map.json").read_text())
KIT = json.loads((BRANDING / "pages" / "pages.json").read_text())
IMAGES_DIR = BRANDING / "pages" / "images"


def _expand(section):
    """{"include": "pages/x.html"} becomes one text section per <h2> in that file."""
    if not (isinstance(section, dict) and "include" in section):
        return [section]
    source = (ROOT / section["include"]).read_text()
    return [part.strip() for part in re.split(r"(?=<h2>)", source) if part.strip()]


PAGES = [{**p, "sections": [s for sec in p["sections"] for s in _expand(sec)]} for p in KIT["pages"]]

JS_OUT = BRANDING / "browser" / KIT["script"]
PROMPTS_OUT = BRANDING / "copilot" / "page-prompts.md"

ALLOWED_TAGS = {"h2", "h3", "h4", "p", "ul", "ol", "li", "a", "strong", "em", "table", "tbody", "tr", "td", "br"}
PLACEHOLDER = re.compile(r"\{\{(list|new):([^}|]+)(?:\|([^}]+))?\}\}")


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def check_pages(errors):
    names = set()
    lists = {lst["listTitle"] for lst in json.loads((ROOT / "sharepoint" / "list-schema.json").read_text())["lists"]}
    for page in PAGES:
        if not re.fullmatch(r"[A-Za-z0-9-]+", page["name"]):
            errors.append(f"page '{page['name']}': name must be letters, digits and hyphens")
        if page["name"] in names:
            errors.append(f"page '{page['name']}' defined twice")
        names.add(page["name"])
        for section in page["sections"]:
            if isinstance(section, dict):
                name = section.get("image", "")
                if not re.fullmatch(r"[A-Za-z0-9-]+\.png", name) or not (IMAGES_DIR / name).is_file():
                    errors.append(f"page '{page['name']}': image '{name}' is not a .png in branding/pages/images")
                if not section.get("alt") or not section.get("caption"):
                    errors.append(f"page '{page['name']}': image '{name}' needs alt text and a caption")
                continue
            for tag in re.findall(r"</?([a-zA-Z0-9]+)", section):
                if tag.lower() not in ALLOWED_TAGS:
                    errors.append(f"page '{page['name']}': <{tag}> is dropped by the text web part")
            for _, title, _ in PLACEHOLDER.findall(section):
                if title not in lists:
                    errors.append(f"page '{page['name']}': no list '{title}' in list-schema.json")
    for page in PAGES:
        for section in page["sections"]:
            if isinstance(section, dict):
                continue
            for target in re.findall(r'href="([^"]+)\.aspx"', section):
                if target not in names:
                    errors.append(f"page '{page['name']}': links to missing page {target}.aspx")


def images():
    """PNG files the pages use, base64-encoded for the browser script to upload."""
    out = {}
    for page in PAGES:
        for section in page["sections"]:
            if isinstance(section, dict) and section["image"] not in out:
                data = (IMAGES_DIR / section["image"]).read_bytes()
                width, height = struct.unpack(">II", data[16:24])
                out[section["image"]] = {"width": width, "height": height, "data": base64.b64encode(data).decode()}
    return out


def column_formats(errors):
    formats = []
    for col in STATUS_MAP["columns"]:
        path = BRANDING / "column-formats" / f"{slug(col['list'])}-{slug(col['field'])}.json"
        if not path.exists():
            errors.append(f"{path.relative_to(ROOT)} missing: run tools/build_formatters.py")
            continue
        formats.append({"list": col["list"], "field": col["field"], "formatter": path.read_text()})
    return formats


JS_TEMPLATE = r"""/*
 * Hutchison Ports look and pages for __SITE__, from the browser.
 * GENERATED by tools/build_site_kit.py from branding/. Don't edit by hand.
 *
 * 1. Open __SITE__, signed in as a Site Owner.
 * 2. Press F12 (or Ctrl+Shift+I / Cmd+Option+I), open Console.
 * 3. Paste this whole file and press Enter. Chrome and Edge may first ask you
 *    to type "allow pasting".
 *
 * Safe to re-run: the theme, column formatting and diagrams are replaced,
 * navigation links are not duplicated, and pages that already exist are left
 * alone unless UPDATE_EXISTING below is true. That rewrites them from this
 * script, so edits made to them on the site are lost.
 */
(async () => {
  const THEME = __THEME__;
  const FORMATS = __FORMATS__;
  const PAGES = __PAGES__;
  const IMAGES = __IMAGES__;
  const UPDATE_EXISTING = false;
  const IMAGE_WP = "d1d91016-032f-456d-98a4-721247c305e8"; // SharePoint Image web part

  const site = (location.pathname.match(/^\/(sites|teams)\/[^/]+/i) || [""])[0];
  const web = location.origin + site;
  const H = { Accept: "application/json;odata=verbose", "Content-Type": "application/json;odata=verbose" };
  const q = (s) => s.replace(/'/g, "''");
  const results = [];
  const log = (step, ok, detail = "") => {
    results.push({ step, result: ok ? "OK" : "FAILED", detail });
    console[ok ? "log" : "warn"](`${ok ? "OK    " : "FAILED"} ${step}${detail ? " - " + detail : ""}`);
  };

  const ctx = await fetch(web + "/_api/contextinfo", { method: "POST", headers: H, credentials: "include" });
  if (!ctx.ok) { console.error(`Can't reach ${web}/_api (HTTP ${ctx.status}). Open the site first.`); return; }
  const digest = (await ctx.json()).d.GetContextWebInformation.FormDigestValue;

  async function sp(path, body, extraHeaders = {}, method = body === undefined ? "GET" : "POST") {
    const r = await fetch(web + path, {
      method, credentials: "include",
      headers: { ...H, "X-RequestDigest": digest, ...extraHeaders },
      body: body === undefined || body === null ? undefined : JSON.stringify(body),
    });
    if (!r.ok) throw new Error(`HTTP ${r.status}: ${(await r.text()).slice(0, 240)}`);
    const t = await r.text();
    return t ? JSON.parse(t).d : null;
  }
  const exists = async (path) => (await fetch(web + path, { headers: H, credentials: "include" })).ok;

  console.log(`Setting up ${web}`);

  // 1. Theme
  try {
    await sp("/_api/ThemeManager/ApplyTheme", {
      name: THEME.name,
      themeJson: JSON.stringify({ palette: THEME.palette, isInverted: THEME.isInverted }),
    });
    log(`Theme '${THEME.name}'`, true);
  } catch (e) { log(`Theme '${THEME.name}'`, false, e.message); }

  // 2. Status column formatting, and each list's URL for page links
  const listUrls = {};
  for (const f of FORMATS) {
    try {
      const l = await sp(`/_api/web/lists/getbytitle('${q(f.list)}')/RootFolder?$select=ServerRelativeUrl`);
      listUrls[f.list] = l.ServerRelativeUrl;
      await sp(`/_api/web/lists/getbytitle('${q(f.list)}')/fields/getbyinternalnameortitle('${q(f.field)}')`,
        { __metadata: { type: "SP.FieldChoice" }, CustomFormatter: f.formatter },
        { "X-HTTP-Method": "MERGE", "IF-MATCH": "*" });
      log(`Format ${f.list} / ${f.field}`, true);
    } catch (e) { log(`Format ${f.list} / ${f.field}`, false, e.message); }
  }

  // 3. Diagrams into Site Assets
  const imageInfo = {};
  if (Object.keys(IMAGES).length) {
    try {
      const lib = await sp("/_api/web/lists/EnsureSiteAssetsLibrary", null);
      const folder = (await sp(`/_api/web/lists(guid'${lib.Id}')/RootFolder?$select=ServerRelativeUrl`)).ServerRelativeUrl;
      const siteId = (await sp("/_api/site?$select=Id")).Id;
      const webId = (await sp("/_api/web?$select=Id")).Id;
      for (const [name, img] of Object.entries(IMAGES)) {
        const bytes = Uint8Array.from(atob(img.data), (c) => c.charCodeAt(0));
        const r = await fetch(`${web}/_api/web/GetFolderByServerRelativeUrl('${q(folder)}')/Files/add(url='${q(name)}',overwrite=true)`, {
          method: "POST", credentials: "include", headers: { Accept: H.Accept, "X-RequestDigest": digest }, body: bytes,
        });
        if (!r.ok) throw new Error(`HTTP ${r.status} uploading ${name}: ${(await r.text()).slice(0, 200)}`);
        const f = (await r.json()).d;
        imageInfo[name] = { url: f.ServerRelativeUrl, uniqueId: f.UniqueId, listId: lib.Id, siteId, webId, width: img.width, height: img.height };
        log(`Upload ${name}`, true, f.ServerRelativeUrl);
      }
    } catch (e) { log("Upload diagrams", false, e.message); }
  }

  // 4. Pages
  const esc = (s) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const fill = (h) => h.replace(/\{\{(list|new):([^}|]+)(?:\|([^}]+))?\}\}/g, (_, kind, title, label) => {
    const url = listUrls[title];
    const text = esc(label || title);
    if (!url) return text;
    return `<a href="${url}${kind === "new" ? "/NewForm.aspx" : ""}">${text}</a>`;
  });
  // A string section is a text web part; an {image, alt, caption} section is an
  // Image web part (select it to open full size) with its caption below.
  const parts = (sections) => sections.flatMap((s) => {
    if (typeof s === "string") return [{ html: fill(s) }];
    const img = imageInfo[s.image];
    if (!img) return [{ html: `<p><em>${esc(s.caption)}</em> (diagram ${esc(s.image)} was not uploaded)</p>` }];
    return [{ section: s, img }, { html: `<p><em>${esc(s.caption)}</em> <a href="${img.url}">Open the diagram full size</a></p>` }];
  });
  const control = (part, i) => {
    const id = crypto.randomUUID();
    const position = { zoneIndex: i + 1, sectionIndex: 1, sectionFactor: 12, layoutIndex: 1, controlIndex: 1 };
    if (part.html) return { controlType: 4, id, position, emphasis: {}, editorType: "CKEditor", innerHTML: part.html };
    const { section: s, img } = part;
    return {
      controlType: 3, id, position, emphasis: {}, webPartId: IMAGE_WP,
      webPartData: {
        id: IMAGE_WP, instanceId: id, title: "Image", description: s.alt, dataVersion: "1.9",
        serverProcessedContent: { htmlStrings: {}, searchablePlainTexts: { captionText: "" }, imageSources: { imageSource: img.url }, links: { linkUrl: img.url } },
        properties: {
          imageSourceType: 2, altText: s.alt, captionText: "", overlayText: "", linkUrl: img.url, fileName: s.image,
          siteId: img.siteId, webId: img.webId, listId: img.listId, uniqueId: img.uniqueId,
          imgWidth: img.width, imgHeight: img.height, alignment: "Center", fixAspectRatio: false,
        },
      },
    };
  };
  const canvas = (sections) => JSON.stringify([
    ...parts(sections).map(control),
    { controlType: 0, pageSettingsSlice: { isDefaultDescription: true, isDefaultThumbnail: true } },
  ]);
  const META = { __metadata: { type: "SP.Publishing.SitePage" } };

  for (const p of PAGES) {
    const url = `${site}/SitePages/${p.name}.aspx`;
    const fileApi = `/_api/web/GetFileByServerRelativeUrl('${q(url)}')`;
    if (await exists(`${fileApi}?$select=Name`)) {
      if (!UPDATE_EXISTING) {
        log(`Page ${p.name}.aspx`, true, "already exists, left as it is (UPDATE_EXISTING = true refreshes it)");
        continue;
      }
      try {
        const id = (await sp(`${fileApi}/ListItemAllFields?$select=Id`)).Id;
        try { await sp(`/_api/sitepages/pages(${id})/checkoutpage`, null); } catch (_) { /* already checked out to you */ }
        await sp(`/_api/sitepages/pages(${id})/savepage`, { ...META, Title: p.title, Description: p.summary, CanvasContent1: canvas(p.sections) }, { "IF-MATCH": "*" });
        await sp(`/_api/sitepages/pages(${id})/publish`, null);
        log(`Page ${p.name}.aspx`, true, "updated and published");
      } catch (e) { log(`Page ${p.name}.aspx`, false, e.message); }
      continue;
    }
    try {
      const page = await sp("/_api/sitepages/pages", { ...META, PageLayoutType: "Article" });
      const id = page.Id;
      try { await sp(`/_api/sitepages/pages(${id})/checkoutpage`, null); } catch (_) { /* new pages start checked out */ }
      await sp(`/_api/sitepages/pages(${id})/savepage`, { ...META, Title: p.title, Description: p.summary, CanvasContent1: canvas(p.sections) }, { "IF-MATCH": "*" });
      try {
        await sp(`/_api/web/GetFileByServerRelativeUrl('${q(site + "/" + page.Url)}')/ListItemAllFields/ValidateUpdateListItem`, {
          formValues: [{ __metadata: { type: "SP.ListItemFormUpdateValue" }, FieldName: "FileLeafRef", FieldValue: p.name }],
          bNewDocumentUpdate: false,
        });
      } catch (e) { log(`Rename ${page.Url} to ${p.name}.aspx`, false, e.message + " (links between pages will need fixing)"); }
      await sp(`/_api/sitepages/pages(${id})/publish`, null);
      log(`Page ${p.name}.aspx`, true, "created and published");
    } catch (e) { log(`Page ${p.name}.aspx`, false, e.message); }
  }

  // 5. Left-hand navigation
  try {
    const nav = await sp("/_api/web/navigation/QuickLaunch?$select=Title");
    const have = new Set(nav.results.map((n) => n.Title));
    for (const p of PAGES) {
      if (!p.nav || have.has(p.nav)) continue;
      await sp("/_api/web/navigation/QuickLaunch", { __metadata: { type: "SP.NavigationNode" }, Title: p.nav, Url: `${site}/SitePages/${p.name}.aspx` });
    }
    log("Navigation links", true);
  } catch (e) { log("Navigation links", false, e.message); }

  console.table(results);
  console.log("Done. Reload the page to see the theme.");
})();
"""


def build_js(formats):
    pages = [{k: p.get(k) for k in ("name", "title", "nav", "summary", "sections")} for p in PAGES]
    js = JS_TEMPLATE
    for key, value in (("__THEME__", {k: THEME[k] for k in ("name", "isInverted", "palette")}),
                       ("__FORMATS__", formats), ("__PAGES__", pages)):
        js = js.replace(key, json.dumps(value, indent=2, ensure_ascii=False).replace("\n", "\n  "))
    js = js.replace("__IMAGES__", json.dumps(images())).replace("__SITE__", KIT["site"])
    return js


def to_text(fragment):
    """Text web part HTML as plain prompt text."""
    t = PLACEHOLDER.sub(lambda m: m.group(3) or m.group(2), fragment)
    t = re.sub(r"<h[234]>(.*?)</h[234]>", r"\n## \1\n", t)
    t = re.sub(r"</td><td>", " | ", t)
    t = re.sub(r"<tr><td>", "\n- ", t)
    t = re.sub(r"<li>", "\n- ", t)
    t = re.sub(r"</p>|</table>|</ul>|</ol>", "\n", t)
    t = re.sub(r"<[^>]+>", "", t)
    t = html.unescape(t)
    return re.sub(r"\n{3,}", "\n\n", t).strip()


def build_prompts():
    out = [
        "# Copilot in SharePoint: page prompts",
        "",
        "GENERATED by `tools/build_site_kit.py` from `branding/pages/pages.json`. Use these when the",
        f"browser script can't be run. On {KIT['site']} choose **+ New → Page**, pick **Create with",
        "Copilot** (or open the Copilot pane in the page editor), paste one prompt, then check the draft",
        "against the facts before you publish. Copilot rewrites wording, so the facts block is what to",
        "check against: rules, statuses, names and column names must match it exactly.",
        "",
        "After publishing, add any links to lists by hand: select the text, **Link**, and pick the list.",
        "",
    ]
    for p in PAGES:
        facts = "\n\n".join(
            to_text(s) if isinstance(s, str) else
            f"[Diagram: {s['caption']} Leave a full-width section here for an Image web part.]"
            for s in p["sections"])
        diagrams = [s for s in p["sections"] if isinstance(s, dict)]
        out += [
            f"## {p['title']}",
            "",
            f"Save the page as **{p['name']}**"
            + (f", add it to the site navigation as **{p['nav']}**." if p.get("nav") else "."),
            "",
            *[f"Diagram: upload `branding/pages/images/{s['image']}` to Site Assets, add it with an **Image** "
              f"web part where the draft marks it, alt text \"{s['alt']}\", and link the image to itself so "
              "readers can open it full size." for s in diagrams],
            *([""] if diagrams else []),
            "```",
            f"Create a SharePoint page titled \"{p['title']}\" for {KIT['site']}.",
            f"Purpose: {p['summary']}",
            f"Audience: {KIT['audience']}. Write in plain British English, sentence-case headings,",
            "short sentences, no emoji, no images. Use text sections and tables only.",
            "Keep every rule, status value, name and column name below word for word;",
            "do not add rules or steps that are not listed.",
            "",
            facts,
            "```",
            "",
        ]
    return "\n".join(out)


def main():
    check = "--check" in sys.argv[1:]
    errors = []
    check_pages(errors)
    formats = column_formats(errors)
    if not errors:
        for path, text in ((JS_OUT, build_js(formats)), (PROMPTS_OUT, build_prompts())):
            rel = path.relative_to(ROOT)
            if check:
                if not path.exists() or path.read_text() != text:
                    errors.append(f"{rel} is out of date: run tools/build_site_kit.py")
            else:
                path.parent.mkdir(exist_ok=True)
                path.write_text(text)
                print(f"wrote {rel}")
    for e in errors:
        print(f"ERROR {e}")
    if not errors and check:
        print(f"OK site kit matches branding/ ({len(PAGES)} pages)")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
